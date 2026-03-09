/* eslint-disable no-console */
const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

initializeApp();
const db = getFirestore();

/**
 * preId 권장 포맷: "chX:sqN"
 * - 예: "ch1:sq7"
 */
function isStandardPreId(preId) {
  return typeof preId === "string" && /^ch\d+:sq\d+$/i.test(preId);
}

/**
 * 챕터 아이디("ch6")에서 숫자만 뽑기
 */
function chapterNumberFromId(chapterId) {
  if (typeof chapterId !== "string") return 0;
  const m = chapterId.match(/^ch(\d+)$/i);
  return m ? Number(m[1]) : 0;
}

/**
 * 6챕터부터 프리미엄 전용 정책
 * - ch1~ch5: 무료
 * - ch6~: premiumRequired
 */
function isPremiumRequiredChapter(chapterId) {
  return chapterNumberFromId(chapterId) >= 6;
}

/**
 * 유저 프리미엄 활성 여부
 * - users/{uid}.premium.isActive === true
 */
function isPremiumActive(userDoc) {
  return !!userDoc?.premium?.isActive;
}

/**
 * 레벨 → 캐릭터 스테이지 매핑
 */
function stageFromLevel(level) {
  if (level >= 15) return "legend";
  if (level >= 10) return "cobling";
  if (level >= 5) return "kid";
  return "egg";
}

/**
 * 이번 레벨업에서 진화가 발생했는지 계산
 */
function computeEvolution(prevLevel, newLevel) {
  const thresholds = [5, 10, 15];

  const crossed = thresholds.filter((t) => prevLevel < t && newLevel >= t);
  if (crossed.length === 0) return null;

  const reachedLevel = Math.max(...crossed);
  return {
    reachedLevel,
    newStage: stageFromLevel(reachedLevel), // reachedLevel 기준
  };
}

/**
 * 완료 전환 체크
 * - before != completed && after == completed
 */
function didBecomeCompleted(before, after) {
  return before?.state !== "completed" && after?.state === "completed";
}

/**
 * 프리미엄 EXP 보너스 적용 함수
 * - 챕터보너스에는 적용하지 않음
 * - users/{uid}.premium.isActive === true 인 경우에만 +5%
 */
function applyPremiumExpBonus(baseExp, userDoc) {
  if (!userDoc?.premium?.isActive) return baseExp;
  return Math.round(baseExp * 1.05);
}

/**
 * [미션추가] KST(UTC+9) 기준 날짜/월 key 생성
 * - dateKey: "YYYY-MM-DD"
 * - monthKey: "YYYY-MM"
 */
function nowKeySeoul() {
  const now = new Date();
  const kst = new Date(now.getTime() + 9 * 60 * 60 * 1000);

  const y = kst.getUTCFullYear();
  const m = String(kst.getUTCMonth() + 1).padStart(2, "0");
  const d = String(kst.getUTCDate()).padStart(2, "0");

  return {
    dateKey: `${y}-${m}-${d}`,
    monthKey: `${y}-${m}`,
  };
}

/**
 * EXP 테이블 공통화 (중복 줄이기)
 */
function getExpTable() {
  return {
    1: 100,
    2: 120,
    3: 160,
    4: 200,
    5: 240,
    6: 310,
    7: 380,
    8: 480,
    9: 600,
    10: 750,
    11: 930,
    12: 1160,
    13: 1460,
    14: 1820,
    15: 2270,
    16: 2840,
    17: 3550,
    18: 4440,
    19: 5550,
  };
}

/**
 * missions/{daily|monthly} 설정(목표치/보상) Firestore에서 읽기
 * - 컬렉션: missions
 * - 문서: daily, monthly
 * - 필드 예:
 *    - isEnabled: true
 *    - targetCount: number
 *    - rewardExp: number
 * - 없으면 기본값으로 폴백
 * - 잦은 읽기 방지를 위해 간단 캐시(TTL) 적용
 */
const _missionConfigCache = {
  daily: { at: 0, data: null },
  monthly: { at: 0, data: null },
}; 

async function getMissionConfig(missionId, defaults) {
  try {
    const now = Date.now();
    const ttlMs = 60 * 1000; // 60초 캐시 (원하시면 늘려도 됩니다)

    const cached = _missionConfigCache[missionId];
    if (cached?.data && now - cached.at < ttlMs) {
      return cached.data;
    }

    const ref = db.collection("missions").doc(missionId); // missions/daily, missions/monthly
    const snap = await ref.get();

    const raw = snap.exists ? snap.data() : null;
    const isEnabled = raw?.isEnabled !== undefined ? !!raw.isEnabled : true;

    const targetCount =
      typeof raw?.targetCount === "number" && Number.isFinite(raw.targetCount)
        ? raw.targetCount
        : defaults.targetCount;

    const rewardExp =
      typeof raw?.rewardExp === "number" && Number.isFinite(raw.rewardExp)
        ? raw.rewardExp
        : defaults.rewardExp;

    const cfg = { isEnabled, targetCount, rewardExp };

    _missionConfigCache[missionId] = { at: now, data: cfg };
    return cfg;
  } catch (e) {
    console.error("❌ getMissionConfig failed:", missionId, e?.message || e);
    return { ...defaults, isEnabled: true };
  }
} 

/**
 * 미션 보상 EXP 지급 (프리미엄 보너스 적용 안 함)
 * - 트랜잭션(t) 안에서 호출 전용
 * - 유저 exp/level + 진화 로직은 기존과 동일
 */
async function grantMissionRewardInTransaction(t, userRef, bonusExp) {
  const userSnap = await t.get(userRef);
  if (!userSnap.exists) return;

  const user = userSnap.data();
  let exp = user.exp || 0;
  let level = user.level || 1;

  const prevLevel = level;

  const expTable = getExpTable();

  exp += bonusExp;

  while (exp >= (expTable[level] || Infinity)) {
    exp -= expTable[level];
    level++;
  }

  const evo = computeEvolution(prevLevel, level);
  const desiredStage = stageFromLevel(level);

  const prevCharacter = user.character || {};
  const prevCustomization = prevCharacter.customization || {};
  const { stage: _legacyStage, ...customizationWithoutStage } = prevCustomization;

  const payload = {
    exp,
    level,
    character: {
      ...prevCharacter,
      stage: prevCharacter.stage || "egg",
      customization: {
        ...customizationWithoutStage,
      },
    },
  };

  if (evo) {
    payload.character.evolutionLevel = evo.reachedLevel;
    payload.character.evolutionPending = true;
    payload.character.evolutionToStage = evo.newStage;
    console.log(`🌟 Evolution! (mission reward) -> ${evo.newStage} (Lv ${evo.reachedLevel})`);
  } else {
    payload.character.stage = desiredStage;
  }

  t.update(userRef, payload);
}

/**
 * [미션추가] missionProgress 문서가 없으면 생성(기존 유저 대응)
 * - daily / monthly 둘 다 보장
 * - 이미 있으면 merge로 유지
 */
async function ensureMissionProgressDocs(userId) {
  const { dateKey, monthKey } = nowKeySeoul();

  const base = db.collection("users").doc(userId).collection("missionProgress");
  const dailyRef = base.doc("daily");
  const monthlyRef = base.doc("monthly");

  // getAll로 한번에 가져오기
  const [dailySnap, monthlySnap] = await db.getAll(dailyRef, monthlyRef);

  const batch = db.batch();
  let changed = 0;

  if (!dailySnap.exists) {
    batch.set(
      dailyRef,
      {
        dateKey,
        count: 0,
        isCompleted: false,
        updatedAt: FieldValue.serverTimestamp(),

        // 보상 중복 지급 방지 필드 기본값
        rewardGranted: false,
        rewardExpGranted: 0,
        rewardGrantedAt: null,
      },
      { merge: true }
    );
    changed++;
    console.log("✅ [미션추가] created missionProgress/daily for", userId);
  }

  if (!monthlySnap.exists) {
    batch.set(
      monthlyRef,
      {
        monthKey,
        count: 0,
        isCompleted: false,
        updatedAt: FieldValue.serverTimestamp(),

        // 보상 중복 지급 방지 필드 기본값
        rewardGranted: false,
        rewardExpGranted: 0,
        rewardGrantedAt: null,
      },
      { merge: true }
    );
    changed++;
    console.log("✅ [미션추가] created missionProgress/monthly for", userId);
  }

  if (changed > 0) {
    await batch.commit();
  }
}

/**
 * [미션추가] 오늘의 미션 증가(서브퀘스트 1개 클리어 = +1)
 * - 문서 없으면 생성
 * - dateKey 바뀌면 자동 리셋 후 증가
 *
 * [미션보상수정]
 * - 일일 미션 "클리어 전환 순간(미완료->완료)"에만 EXP 지급
 * - 프리미엄/퍼펙트 무관, 1일 1회만
 *
 * 
 * - targetCount / rewardExp를 missions/daily에서 읽어서 적용
 *
 * 
 * - 이번 클리어에서 "방금 완료됐는지"를 호출부가 알 수 있도록
 *   결과 객체를 return 하도록 변경
 */
async function incrementDailyMission(userId, targetCount = 2, rewardExp = 120) {
  const { dateKey } = nowKeySeoul();
  const userRef = db.collection("users").doc(userId); 
  const ref = userRef.collection("missionProgress").doc("daily");

  // 호출부에서 사용할 결과값
  let result = {
    wasCompleted: false,
    isCompleted: false,
    didJustComplete: false,
    rewardGrantedNow: false,
    rewardExpGranted: 0,
    count: 0,
    dateKey,
  };

  await db.runTransaction(async (t) => {
    const snap = await t.get(ref);
    const data = snap.exists ? snap.data() : {};

    const curKey = data?.dateKey || "";
    let count = data?.count || 0;
    let isCompleted = !!data?.isCompleted;

    // 보상 지급 여부
    let rewardGranted = !!data?.rewardGranted;

    // 날짜가 바뀌면 리셋
    if (curKey !== dateKey) {
      count = 0;
      isCompleted = false;

      // 날짜 바뀌면 보상 플래그도 리셋
      rewardGranted = false;
    }

    const wasCompleted = isCompleted; 

    count += 1;
    if (count >= targetCount) isCompleted = true;

    // "이번 트랜잭션에서" 완료로 전환되었는지
    const becameCompletedNow = !wasCompleted && isCompleted;

    // 기본 결과 먼저 세팅
    result = {
      wasCompleted,
      isCompleted,
      didJustComplete: becameCompletedNow,
      rewardGrantedNow: false,
      rewardExpGranted: 0,
      count,
      dateKey,
    };

    // 완료 전환 + 아직 보상 미지급이면 (missions/daily의 rewardExp) 지급
    if (becameCompletedNow && !rewardGranted) {
      const dailyRewardExp = rewardExp; // 하드코딩 제거
      await grantMissionRewardInTransaction(t, userRef, dailyRewardExp);

      rewardGranted = true;

      t.set(
        ref,
        {
          dateKey,
          count,
          isCompleted,
          rewardGranted: true,
          rewardExpGranted: dailyRewardExp,
          rewardGrantedAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      // 보상 지급까지 반영한 결과값
      result = {
        wasCompleted,
        isCompleted,
        didJustComplete: true,
        rewardGrantedNow: true,
        rewardExpGranted: dailyRewardExp,
        count,
        dateKey,
      };

      console.log("🎁 Daily mission reward granted:", { userId, dateKey, exp: dailyRewardExp });
      return;
    }

    // 기본 업데이트(보상 미발생)
    t.set(
      ref,
      {
        dateKey,
        count,
        isCompleted,
        rewardGranted,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  });

  // 호출부에서 사용할 수 있도록 반환
  return result;
}

/**
 * [미션추가] 월간 미션 증가(챕터 올클 1개 = +1)
 * - 문서 없으면 생성
 * - monthKey 바뀌면 자동 리셋 후 증가
 *
 * [미션보상수정]
 * - 월간 미션 "성공 전환 순간(미완료->완료)"에만 EXP 지급
 * - 프리미엄/퍼펙트 무관, 1달 1회만
 *
 * 
 * - targetCount / rewardExp를 missions/monthly에서 읽어서 적용
 *
 * 
 * - 이번 클리어에서 "방금 완료됐는지"를 호출부가 알 수 있도록
 *   결과 객체를 return 하도록 변경
 */
async function incrementMonthlyMission(userId, targetCount = 1, rewardExp = 400) {
  const { monthKey } = nowKeySeoul();
  const userRef = db.collection("users").doc(userId); // 
  const ref = userRef.collection("missionProgress").doc("monthly");

  // 호출부에서 사용할 결과값
  let result = {
    wasCompleted: false,
    isCompleted: false,
    didJustComplete: false,
    rewardGrantedNow: false,
    rewardExpGranted: 0,
    count: 0,
    monthKey,
  };

  await db.runTransaction(async (t) => {
    const snap = await t.get(ref);
    const data = snap.exists ? snap.data() : {};

    const curKey = data?.monthKey || "";
    let count = data?.count || 0;
    let isCompleted = !!data?.isCompleted;

    // 보상 지급 여부
    let rewardGranted = !!data?.rewardGranted;

    // 월이 바뀌면 리셋
    if (curKey !== monthKey) {
      count = 0;
      isCompleted = false;

      // 월 바뀌면 보상 플래그도 리셋
      rewardGranted = false;
    }

    const wasCompleted = isCompleted; // 

    count += 1;
    if (count >= targetCount) isCompleted = true;

    // "이번 트랜잭션에서" 완료로 전환되었는지
    const becameCompletedNow = !wasCompleted && isCompleted;

    // 기본 결과 먼저 세팅
    result = {
      wasCompleted,
      isCompleted,
      didJustComplete: becameCompletedNow,
      rewardGrantedNow: false,
      rewardExpGranted: 0,
      count,
      monthKey,
    };

    // 완료 전환 + 아직 보상 미지급이면 (missions/monthly의 rewardExp) 지급
    if (becameCompletedNow && !rewardGranted) {
      const monthlyRewardExp = rewardExp; // 하드코딩 제거
      await grantMissionRewardInTransaction(t, userRef, monthlyRewardExp);

      rewardGranted = true;

      t.set(
        ref,
        {
          monthKey,
          count,
          isCompleted,
          rewardGranted: true,
          rewardExpGranted: monthlyRewardExp,
          rewardGrantedAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      // 보상 지급까지 반영한 결과값
      result = {
        wasCompleted,
        isCompleted,
        didJustComplete: true,
        rewardGrantedNow: true,
        rewardExpGranted: monthlyRewardExp,
        count,
        monthKey,
      };

      console.log("🎁 Monthly mission reward granted:", { userId, monthKey, exp: monthlyRewardExp });
      return;
    }

    // 기본 업데이트(보상 미발생)
    t.set(
      ref,
      {
        monthKey,
        count,
        isCompleted,
        rewardGranted,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  });

  // 호출부에서 사용할 수 있도록 반환
  return result;
}

/**
 * 보상 정산 완료 플래그를 subQuest progress 문서에 기록
 * - "모든 EXP 트랜잭션이 끝난 뒤" iOS가 이것을 보고 진화화면을 띄움
 * - 한 번만 true로 찍히도록 설계 (merge)
 */
async function markRewardSettled(subQuestProgressRef, meta = {}) {
  await subQuestProgressRef.set(
    {
      rewardSettled: true,
      rewardSettledAt: FieldValue.serverTimestamp(),
      rewardSettleVersion: 1, //디버깅/확장용
      ...meta, // 어떤 단계에서 settled 되었는지 남기고 싶으면 사용
    },
    { merge: true }
  );
}

/**
 * (중요) 해금 타겟 찾기: where() 절대 사용하지 않고 전부 스캔
 * - FAILED_PRECONDITION(인덱스 문제) 원천 차단
 *
 * 지원하는 preId 형태:
 *  1) 표준: "chX:sqN"
 *  2) 레거시: "sqN" (같은 챕터 기준)
 *  3) 오브젝트: { chapter: "chX", sub: "sqN" } (권장 X)
 */
async function findUnlockTargetsByScan({ chapterId, subQuestId }) {
  const fullKey = `${chapterId}:${subQuestId}`; // 예: ch1:sq7
  const targets = [];

  console.log("🔎 [SCAN START]", { chapterId, subQuestId, fullKey });

  const questsSnap = await db.collection("quests").get();

  for (const q of questsSnap.docs) {
    const subSnap = await q.ref.collection("subQuests").get();

    subSnap.forEach((d) => {
      const data = d.data();
      const p = data.preId;

      console.log("[SCAN]", {
        questDocId: q.id,
        subQuestDocId: d.id,
        preIdRaw: p,
        preIdJSON: JSON.stringify(p),
        matchTarget: fullKey,
      });

      // 1) 표준: "chX:sqN"
      if (typeof p === "string" && p.includes(":")) {
        if (p === fullKey) targets.push({ nextChapterId: q.id, nextSubQuestId: d.id });
        return;
      }

      // 2) 레거시: "sqN" (같은 챕터 기준)
      if (typeof p === "string" && !p.includes(":")) {
        if (q.id === chapterId && p === subQuestId) {
          targets.push({ nextChapterId: q.id, nextSubQuestId: d.id });
        }
        return;
      }

      // 3) 오브젝트: { chapter, sub }
      if (p && typeof p === "object" && p.chapter && p.sub) {
        if (p.chapter === chapterId && p.sub === subQuestId) {
          targets.push({ nextChapterId: q.id, nextSubQuestId: d.id });
        }
      }
    });
  }

  return { fullKey, targets };
}

/**
 * 해금 적용(안전)
 * - locked(또는 문서 없음)일 때만 inProgress로 변경
 * - 이미 completed/inProgress면 절대 덮어쓰지 않음
 * - 자기 자신은 절대 건드리지 않음
 */
async function applyUnlockSafely({ userId, fromChapterId, fromSubQuestId, targets, fullKey }) {
  if (!targets || targets.length === 0) {
    console.log(`🔎 해금 대상 없음 for ${fullKey}`);
    return;
  }

  // 중복 제거 + 자기 자신 제거
  const unique = new Map();
  for (const t of targets) {
    if (t.nextChapterId === fromChapterId && t.nextSubQuestId === fromSubQuestId) continue;
    unique.set(`${t.nextChapterId}:${t.nextSubQuestId}`, t);
  }

  if (unique.size === 0) {
    console.log(`ℹ️ 해금 대상은 있었지만(중복/자기자신) 제거 후 0개 for ${fullKey}`);
    return;
  }

  const userRef = db.collection("users").doc(userId);

  // 유저 프리미엄 여부를 해금 로직에서도 확인 (ch6~ 프리미엄 잠금 유지)
  const userSnap = await userRef.get(); 
  const userDoc = userSnap.exists ? userSnap.data() : null;
  const premiumActive = isPremiumActive(userDoc);

  const refs = [];
  const items = [];
  for (const { nextChapterId, nextSubQuestId } of unique.values()) {
    const ref = userRef.collection("progress").doc(nextChapterId).collection("subQuests").doc(nextSubQuestId);

    refs.push(ref);
    items.push({ ref, nextChapterId, nextSubQuestId });
  }

  const snaps = await db.getAll(...refs);
  const batch = db.batch();
  let changed = 0;

  snaps.forEach((snap, idx) => {
    const { ref, nextChapterId, nextSubQuestId } = items[idx];
    const curState = snap.exists ? snap.data().state : null;

    // 6챕터부터 프리미엄 전용: 비프리미엄이면 premiumLocked 유지/설정
    if (isPremiumRequiredChapter(nextChapterId) && !premiumActive) {
      if (!snap.exists) {
        batch.set(
          ref,
          {
            questId: nextChapterId,
            subQuestId: nextSubQuestId,
            state: "premiumLocked", 
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
        changed++;
        console.log(`🔒 premiumLocked (create) => ${nextChapterId}/${nextSubQuestId}`);
      } else {
        console.log(`↪︎ skip unlock (premium) => ${nextChapterId}/${nextSubQuestId} (state=${curState})`);
      }
      return;
    }

    // premiumLocked 상태는 절대 inProgress로 풀지 않음
    if (curState === "premiumLocked") {
      console.log(`↪︎ skip unlock => ${nextChapterId}/${nextSubQuestId} (state=premiumLocked)`);
      return;
    }

    if (!snap.exists || curState === "locked") {
      batch.set(
        ref,
        {
          questId: nextChapterId,
          subQuestId: nextSubQuestId,
          state: "inProgress",
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
      changed++;
      console.log(`🔓 unlock => ${nextChapterId}/${nextSubQuestId}`);
    } else {
      console.log(`↪︎ skip unlock => ${nextChapterId}/${nextSubQuestId} (state=${curState})`);
    }
  });

  if (changed > 0) {
    await batch.commit();
    console.log(`🔓 다음 퀘스트 해금 완료 for user ${userId} (from ${fullKey}), changed=${changed}`);
  } else {
    console.log(`ℹ️ 해금 대상은 있었지만 locked가 없어 변경 없음 for user ${userId} (from ${fullKey})`);
  }
}

/**
 * 유저 생성 시 기본 세팅 + progress 초기화
 *  - users/{uid}
 *  - users/{uid}/progress/{chapterId}/subQuests/{subQuestId}
 *  - ch1의 첫 서브퀘스트만 inProgress, 나머지는 locked
 */
exports.initUserProgress = onDocumentCreated("users/{userId}", async (event) => {
  const userId = event.params.userId;
  const userRef = db.collection("users").doc(userId);

  // 기본 정보
  await userRef.set(
    {
      level: 1,
      exp: 0,
      lastLogin: FieldValue.serverTimestamp(),
      character: {
        stage: "egg",
        customization: {},
        evolutionLevel: 0,
        evolutionPending: false,
        evolutionToStage: "egg", // 진화 연출용 목표 스테이지(없어도 되지만 UX/데이터 일관성에 좋음)
      },
      premium: { isActive: false }, // 기본값(원하시면 제거 가능)
    },
    { merge: true }
  );

  // 유저 생성 시점에 missionProgress(daily/monthly) 기본 문서 생성
  await ensureMissionProgressDocs(userId);

  // init 시점 유저 프리미엄 상태
  const createdUserSnap = await userRef.get();
  const createdUserDoc = createdUserSnap.exists ? createdUserSnap.data() : null;
  const premiumActive = isPremiumActive(createdUserDoc);

  // 모든 챕터/서브퀘스트 progress 생성
  const chaptersSnap = await db.collection("quests").get();

  for (const chapterDoc of chaptersSnap.docs) {
    const subQuestsSnap = await chapterDoc.ref.collection("subQuests").orderBy("order").get();

    let index = 0;
    const batch = db.batch();

    subQuestsSnap.forEach((sqDoc) => {
      const progressRef = userRef.collection("progress").doc(chapterDoc.id).collection("subQuests").doc(sqDoc.id);

      let state = "locked";

      // 6챕터부터 프리미엄 전용: 비프리미엄이면 premiumLocked로 생성
      if (isPremiumRequiredChapter(chapterDoc.id) && !premiumActive) {
        state = "premiumLocked";
      } else {
        if (chapterDoc.id === "ch1" && index === 0) state = "inProgress";
      }

      batch.set(progressRef, {
        questId: chapterDoc.id,
        subQuestId: sqDoc.id,
        state,
        earnedExp: 0,
        attempts: 0,
        perfectClear: false,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });

      index++;
    });

    await batch.commit();
    console.log(`✅ ${chapterDoc.id} progress 초기화 완료`);
  }

  console.log(`✅ User ${userId} initialized with level/exp and all progress`);
  return true;
});

/**
 * 진화 연출이 "끝난 뒤" stage를 서버에서 확정하는 트리거
 *
 * 동작 방식:
 * - iOS가 진화 연출이 끝나면 users/{uid} 문서에:
 *    character.evolutionPending = false
 *   만 업데이트(또는 evolutionPending true -> false) 해주면 됨
 *
 * 서버가 자동으로:
 * - character.stage = character.evolutionToStage 로 확정
 * - evolutionToStage / evolutionLevel 정리(원하면)
 *
 * 이걸 추가하면 "진화는 끝났는데 stage가 안 바뀌는" 문제가 해결됩니다.
 */
exports.applyEvolutionStageOnPendingCleared = onDocumentUpdated("users/{userId}", async (event) => {
  const { userId } = event.params;
  const before = event.data.before.data();
  const after = event.data.after.data();
  if (!before || !after) return;

  const bChar = before.character || {};
  const aChar = after.character || {};

  const wasPending = !!bChar.evolutionPending;
  const isPending = !!aChar.evolutionPending;

  // pending이 true -> false로 "전환"된 순간만 처리
  if (!(wasPending && !isPending)) {
    return true;
  }

  const toStage = (aChar.evolutionToStage || "").trim().toLowerCase();
  const curStage = (aChar.stage || "").trim().toLowerCase();

  // toStage가 비정상이면 아무것도 안 함
  const allowed = new Set(["egg", "kid", "cobling", "legend"]);
  if (!allowed.has(toStage)) {
    console.log("⚠️ evolutionToStage invalid, skip apply:", { userId, toStage, curStage });
    return true;
  }

  // 이미 stage가 같으면 굳이 업데이트 안 함(무한루프 방지)
  if (curStage === toStage) {
    console.log("ℹ️ stage already applied, skip:", { userId, curStage, toStage });
    return true;
  }

  const userRef = db.collection("users").doc(userId);

  // stage 확정 + 정리
  await userRef.set(
    {
      character: {
        stage: toStage,
        evolutionAppliedAt: FieldValue.serverTimestamp(),
        evolutionToStage: FieldValue.delete(), // 확정 후 목표값 제거
        evolutionLevel: FieldValue.delete(), // 확정 후 정리(원치 않으면 삭제 라인 제거)
      },
    },
    { merge: true }
  );

  console.log("✅ Evolution stage applied:", { userId, from: curStage, to: toStage });
  return true;
});

/**
 * progress 업데이트 훅
 *  - EXP/레벨 반영 (earnedExp 증가분만)
 *  - 챕터 완료 보너스 (해당 챕터의 모든 subQuest가 completed일 때, 1회만)
 *  - 다음 서브퀘스트 해금 (state가 completed로 "전환"되는 시점에만)
 *
 * 중요:
 * - 해금 타겟 조회에서 where() 제거 → FAILED_PRECONDITION 방지
 * - 해금 적용 시 locked일 때만 inProgress로 변경
 */
exports.updateUserExpOnClear = onDocumentUpdated(
  "users/{userId}/progress/{chapterId}/subQuests/{subQuestId}",
  async (event) => {
    const { userId, chapterId, subQuestId } = event.params;
    const before = event.data.before.data();
    const after = event.data.after.data();
    if (!before || !after) return;

    // 프리미엄 전용 챕터(ch6~)인데 비프리미엄 유저가 업데이트를 시도하면 서버에서 차단
    const gateUserRef = db.collection("users").doc(userId);
    const gateUserSnap = await gateUserRef.get();
    const gateUserDoc = gateUserSnap.exists ? gateUserSnap.data() : null;
    if (isPremiumRequiredChapter(chapterId) && !isPremiumActive(gateUserDoc)) {
      console.log("🚫 Non-premium attempted to update premium chapter progress. Skip.", { userId, chapterId, subQuestId });
      return true;
    }

    // 현재 subQuest progress ref를 공통으로 사용 (정산 완료 플래그 기록용)
    const subQuestProgressRef = event.data.after.ref;

    // 이번 업데이트 사이클에서 "정산 완료"를 언제 찍을지 결정하기 위한 플래그
    // - 챕터 보너스까지 있는 케이스는 챕터 트랜잭션 끝난 뒤에만 settled 찍어야 함
    let shouldSettleAfterChapterBonus = false;

    // 성공 다이얼로그에서 사용할 "이번 클리어 기준 미션 결과" 기본값
    let dailyMissionResult = {
      wasCompleted: false,
      isCompleted: false,
      didJustComplete: false,
      rewardGrantedNow: false,
      rewardExpGranted: 0,
      count: 0,
      dateKey: null,
    };

    let monthlyMissionResult = {
      wasCompleted: false,
      isCompleted: false,
      didJustComplete: false,
      rewardGrantedNow: false,
      rewardExpGranted: 0,
      count: 0,
      monthKey: null,
    };

    // ----- (A) EXP 업데이트: earnedExp 증가분만 반영 -----
    const beforeExp = before.earnedExp || 0;
    const afterExp = after.earnedExp || 0;
    const deltaExp = afterExp - beforeExp;

    if (deltaExp > 0) {
      console.log(`🎉 SubQuest ${chapterId}/${subQuestId} → +${deltaExp} exp for user ${userId}`);
      const userRef = db.collection("users").doc(userId);

      await db.runTransaction(async (t) => {
        const userSnap = await t.get(userRef);
        if (!userSnap.exists) return;

        const user = userSnap.data();
        let exp = user.exp || 0;
        let level = user.level || 1;

        const prevLevel = level;

        // 프리미엄 EXP 보너스(서브퀘스트에만 적용)
        const deltaExpWithPremium = applyPremiumExpBonus(deltaExp, user);

        // 기존 exp += deltaExp; 대신 프리미엄 적용 값 사용
        exp += deltaExpWithPremium;

        // 로그도 실제 반영값 기준으로 남기기(디버깅 편함)
        console.log(
          `⭐ premium=${!!user?.premium?.isActive} deltaExp=${deltaExp} -> applied=${deltaExpWithPremium}`
        );

        const expTable = getExpTable(); // 공통 함수 사용

        while (exp >= (expTable[level] || Infinity)) {
          exp -= expTable[level];
          level++;
        }

        // 이번 트랜잭션에서 진화가 발생했는지 체크
        const evo = computeEvolution(prevLevel, level);

        // 레벨 기반 스테이지 (항상 동기화)
        const desiredStage = stageFromLevel(level);

        // ============================
        // prevCharacter / prevCustomization 정의
        // ============================
        const prevCharacter = user.character || {};
        const prevCustomization = prevCharacter.customization || {};

        // ============================
        // customization.stage가 남아있어도 payload에서 제거
        // - Firestore update에서 character(부모) + character.customization.stage(자식) 동시 지정 시 충돌 발생
        // - 그래서 FieldValue.delete()를 payload에서 제거하고,
        //   애초에 customization 객체에서 stage를 빼서 저장합니다.
        // ============================
        const { stage: _legacyStage, ...customizationWithoutStage } = prevCustomization;

        const payload = {
          exp,
          level,
          lastLogin: FieldValue.serverTimestamp(),

          character: {
            ...prevCharacter,

            // 진화가 "발생한 경우" stage를 즉시 바꾸지 않음 (진화 연출이 BEFORE→AFTER로 자연스럽게)
            // - evo가 없으면 아래 else에서 desiredStage로 동기화
            stage: prevCharacter.stage || "egg",

            customization: {
              ...customizationWithoutStage, // stage 제거된 customization만 저장
            },
          },

          // ❌ [삭제] 아래 줄이 character(부모)와 충돌을 일으켜 에러 발생
          // "character.customization.stage": FieldValue.delete(),
        };

        if (evo) {
          payload.character.evolutionLevel = evo.reachedLevel;
          payload.character.evolutionPending = true;
          payload.character.evolutionToStage = evo.newStage; // 진화 완료 시 확정될 목표 스테이지 저장
          console.log(`🌟 Evolution! user=${userId} -> ${evo.newStage} (Lv ${evo.reachedLevel})`);
        } else {
          payload.character.stage = desiredStage; // 진화가 없으면 stage는 레벨 기반으로 계속 동기화
        }

        t.update(userRef, payload);
      });
    } else {
      console.log(`ℹ️ 경험치 증가 없음: ${chapterId}/${subQuestId}`);
    }

    // 완료 전환 체크
    const becameCompletedNow = didBecomeCompleted(before, after);

    // 기존 유저도 missionProgress가 없을 수 있으니, 완료 전환 시점에 보장 생성
    if (becameCompletedNow) {
      await ensureMissionProgressDocs(userId);
    }

    // 오늘의 미션: 서브퀘스트 completed 전환 순간에 +1
    if (becameCompletedNow) {
      try {
        // missions/daily에서 목표치/보상치 읽어서 적용
        const dailyCfg = await getMissionConfig("daily", { targetCount: 2, rewardExp: 120 }); 
        if (dailyCfg.isEnabled) {
          // 반환값을 받아서 "방금 완료 여부" 추적
          dailyMissionResult = await incrementDailyMission(userId, dailyCfg.targetCount, dailyCfg.rewardExp);
        } else {
          console.log("ℹ️ Daily mission disabled (missions/daily.isEnabled=false)");
        }
        console.log("✅ [미션추가] daily mission incremented:", {
          userId,
          chapterId,
          subQuestId,
          dailyMissionResult,
        });
      } catch (e) {
        console.error("❌ [미션추가] daily mission increment failed:", e?.message || e);
      }
    }

    // ----- (B) 챕터 전체 클리어 보너스: 완료 전환 시점에만 검사 -----
    if (becameCompletedNow) {
      const chapterProgressRef = db.collection("users").doc(userId).collection("progress").doc(chapterId);

      const chapterSnap = await chapterProgressRef.get();
      if (chapterSnap.exists && chapterSnap.data().chapterBonusGranted) {
        console.log(`⚠️ Chapter ${chapterId} 보너스 이미 지급됨`);

        // settled 시점에 이번 클리어 결과(일일/월간)를 함께 기록
        await markRewardSettled(subQuestProgressRef, {
          settledBy: "chapterBonusAlreadyGranted",
          didJustCompleteDailyMission: !!dailyMissionResult.didJustComplete,
          isDailyMissionCompleted: !!dailyMissionResult.isCompleted,
          dailyMissionRewardGrantedNow: !!dailyMissionResult.rewardGrantedNow,
          dailyMissionRewardExpGranted: dailyMissionResult.rewardExpGranted || 0,

          didJustCompleteMonthlyMission: !!monthlyMissionResult.didJustComplete,
          isMonthlyMissionCompleted: !!monthlyMissionResult.isCompleted,
          monthlyMissionRewardGrantedNow: !!monthlyMissionResult.rewardGrantedNow,
          monthlyMissionRewardExpGranted: monthlyMissionResult.rewardExpGranted || 0,
        });
      } else {
        const subQuestsSnap = await chapterProgressRef.collection("subQuests").get();
        const allCompleted =
          subQuestsSnap.docs.length > 0 && subQuestsSnap.docs.every((doc) => doc.data().state === "completed");

        if (allCompleted) {
          shouldSettleAfterChapterBonus = true;

          // ============================
          // 챕터 클리어 보상 고정 140 EXP 지급 (❗프리미엄 적용 안 함)
          // ============================
          const bonusExp = 140; // 고정 챕터 보상 (모든 챕터 동일)
          console.log(`🏆 Chapter ${chapterId} 완료 보상 지급 (+${bonusExp} exp)`);

          const userRef = db.collection("users").doc(userId);
          await db.runTransaction(async (t) => {
            const userSnap = await t.get(userRef);
            if (!userSnap.exists) return;

            const user = userSnap.data();
            let exp = user.exp || 0;
            let level = user.level || 1;

            const prevLevel = level;

            const expTable = getExpTable(); // 공통 함수 사용

            exp += bonusExp;

            while (exp >= (expTable[level] || Infinity)) {
              exp -= expTable[level];
              level++;
            }

            const evo = computeEvolution(prevLevel, level);
            const desiredStage = stageFromLevel(level);

            const prevCharacter = user.character || {};
            const prevCustomization = prevCharacter.customization || {};

            const { stage: _legacyStage2, ...customizationWithoutStage2 } = prevCustomization;

            const payload = {
              exp,
              level,

              character: {
                ...prevCharacter,
                stage: prevCharacter.stage || "egg",
                customization: {
                  ...customizationWithoutStage2,
                },
              },
            };

            if (evo) {
              payload.character.evolutionLevel = evo.reachedLevel;
              payload.character.evolutionPending = true;
              payload.character.evolutionToStage = evo.newStage;
              console.log(`🌟 Evolution! user=${userId} -> ${evo.newStage} (Lv ${evo.reachedLevel})`);
            } else {
              payload.character.stage = desiredStage;
            }

            t.update(userRef, payload);
            t.set(chapterProgressRef, { chapterBonusGranted: true }, { merge: true });

            t.set(
              subQuestProgressRef,
              {
                chapterClearGranted: true,
                chapterBonusExpGranted: bonusExp,
                chapterBonusGrantedAt: FieldValue.serverTimestamp(),
              },
              { merge: true }
            );
          });

          // 월간 미션: 챕터 올클(보너스 지급) 확정 순간에 +1
          // - chapterBonusGranted로 중복 방지되므로, 여기서 올리면 월간도 중복 증가가 없습니다.
          try {
            await ensureMissionProgressDocs(userId); // 혹시 없으면 생성

            // missions/monthly에서 목표치/보상치 읽어서 적용
            const monthlyCfg = await getMissionConfig("monthly", { targetCount: 1, rewardExp: 400 }); 
            if (monthlyCfg.isEnabled) {
              // 반환값을 받아서 "방금 완료 여부" 추적
              monthlyMissionResult = await incrementMonthlyMission(
                userId,
                monthlyCfg.targetCount,
                monthlyCfg.rewardExp
              );
            } else {
              console.log("ℹ️ Monthly mission disabled (missions/monthly.isEnabled=false)");
            }

            console.log("✅ [미션추가] monthly mission incremented:", {
              userId,
              chapterId,
              monthlyMissionResult,
            });
          } catch (e) {
            console.error("❌ [미션추가] monthly mission increment failed:", e?.message || e);
          }

          // settled 시점에 이번 클리어 결과(일일/월간)를 함께 기록
          await markRewardSettled(subQuestProgressRef, {
            settledBy: "chapterBonusGranted",
            didJustCompleteDailyMission: !!dailyMissionResult.didJustComplete,
            isDailyMissionCompleted: !!dailyMissionResult.isCompleted,
            dailyMissionRewardGrantedNow: !!dailyMissionResult.rewardGrantedNow,
            dailyMissionRewardExpGranted: dailyMissionResult.rewardExpGranted || 0,

            didJustCompleteMonthlyMission: !!monthlyMissionResult.didJustComplete,
            isMonthlyMissionCompleted: !!monthlyMissionResult.isCompleted,
            monthlyMissionRewardGrantedNow: !!monthlyMissionResult.rewardGrantedNow,
            monthlyMissionRewardExpGranted: monthlyMissionResult.rewardExpGranted || 0,
          });
        }
      }
    }

    // ----- (C) 다음 서브퀘스트 해금: 완료 전환 시점에만 실행 -----
    if (!becameCompletedNow) {
      console.log("ℹ️ 완료 상태 전환 아님 → 해금/보너스 스킵");
      return true;
    }

    if (!shouldSettleAfterChapterBonus) {
      // 일반 서브퀘스트 클리어도 settled 시점에 이번 미션 결과 기록
      await markRewardSettled(subQuestProgressRef, {
        settledBy: "subQuestClearOnly",
        didJustCompleteDailyMission: !!dailyMissionResult.didJustComplete,
        isDailyMissionCompleted: !!dailyMissionResult.isCompleted,
        dailyMissionRewardGrantedNow: !!dailyMissionResult.rewardGrantedNow,
        dailyMissionRewardExpGranted: dailyMissionResult.rewardExpGranted || 0,

        didJustCompleteMonthlyMission: !!monthlyMissionResult.didJustComplete,
        isMonthlyMissionCompleted: !!monthlyMissionResult.isCompleted,
        monthlyMissionRewardGrantedNow: !!monthlyMissionResult.rewardGrantedNow,
        monthlyMissionRewardExpGranted: monthlyMissionResult.rewardExpGranted || 0,
      });
    }

    let fullKey = `${chapterId}:${subQuestId}`;
    try {
      const res = await findUnlockTargetsByScan({ chapterId, subQuestId });
      fullKey = res.fullKey;

      await applyUnlockSafely({
        userId,
        fromChapterId: chapterId,
        fromSubQuestId: subQuestId,
        targets: res.targets,
        fullKey,
      });
    } catch (e) {
      console.error("unlock scan failed:", e?.message || e);
      console.log(`🔎 해금 대상 없음 for ${fullKey}`);
    }

    return true;
  }
);

/**
 * 새로운 Chapter가 추가될 때 모든 유저 progress 생성
 *  - ch1의 첫 서브퀘스트만 inProgress, 나머지는 locked
 *  - 기존 문서가 있으면 상태 보존(덮어쓰기 방지)
 */
exports.onChapterCreated = onDocumentCreated("quests/{chapterId}", async (event) => {
  const chapterId = event.params.chapterId;
  console.log(`📘 New Chapter created: ${chapterId}`);

  const subQuestsSnap = await event.data.ref.collection("subQuests").orderBy("order").get();
  if (subQuestsSnap.empty) {
    console.log("⚠️ subQuests 없음 → progress 생성 안 함");
    return true;
  }

  const usersSnap = await db.collection("users").get();
  for (const userDoc of usersSnap.docs) {
    const batch = db.batch();
    let index = 0;

    // 유저별 프리미엄 상태 확인
    const userData = userDoc.data();
    const premiumActive = isPremiumActive(userData);

    for (const sqDoc of subQuestsSnap.docs) {
      const progressRef = userDoc.ref.collection("progress").doc(chapterId).collection("subQuests").doc(sqDoc.id);

      const existed = await progressRef.get();
      if (existed.exists) continue;

      let state = "locked";

      // 6챕터부터 프리미엄 전용: 비프리미엄이면 premiumLocked
      if (isPremiumRequiredChapter(chapterId) && !premiumActive) {
        state = "premiumLocked";
      } else {
        if (index === 0 && chapterId === "ch1") state = "inProgress";
      }

      batch.set(progressRef, {
        questId: chapterId,
        subQuestId: sqDoc.id,
        state,
        earnedExp: 0,
        attempts: 0,
        perfectClear: false,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });

      index++;
    }

    await batch.commit();
    console.log(`✅ User ${userDoc.id} → ${chapterId} progress 추가 완료 (보존모드)`);
  }

  return true;
});

/**
 * 새로운 SubQuest가 추가될 때 모든 유저 progress 생성
 *  - preId 조건을 확인하여 초기 state(inProgress/locked) 결정
 *  - 크로스 챕터 preId도 지원
 *  - 기존 문서가 있으면 상태 보존(덮어쓰기 방지)
 *
 * 권장 정책:
 *  - preId는 "chX:sqN"으로 통일
 */
exports.onSubQuestCreated = onDocumentCreated("quests/{chapterId}/subQuests/{subQuestId}", async (event) => {
  const { chapterId, subQuestId } = event.params;
  console.log(`🧩 New SubQuest created: ${chapterId}/${subQuestId}`);

  const newSubQuestData = event.data.data();
  const preId = newSubQuestData.preId || null;

  if (preId && !isStandardPreId(preId) && !(typeof preId === "string") && !(typeof preId === "object")) {
    console.warn(`⚠️ preId 타입 이상: ${chapterId}/${subQuestId}`, preId);
  }
  if (typeof preId === "string" && preId.includes(":") && !isStandardPreId(preId)) {
    console.warn(`⚠️ preId 표준 포맷 아님(권장: chX:sqN): ${chapterId}/${subQuestId} preId=${preId}`);
  }

  const usersSnap = await db.collection("users").get();
  for (const userDoc of usersSnap.docs) {
    const userRef = userDoc.ref;

    const progressRef = userRef.collection("progress").doc(chapterId).collection("subQuests").doc(subQuestId);

    const existed = await progressRef.get();
    if (existed.exists) {
      console.log(`↪︎ skip: ${userDoc.id} already has ${chapterId}/${subQuestId}`);
      continue;
    }

    // 유저별 프리미엄 상태 확인
    const premiumActive = isPremiumActive(userDoc.data());

    let initialState = "locked";

    // 6챕터부터 프리미엄 전용: 비프리미엄이면 무조건 premiumLocked (선행조건과 무관)
    if (isPremiumRequiredChapter(chapterId) && !premiumActive) {
      initialState = "premiumLocked";
    } else if (!preId) {
      initialState = "inProgress";
    } else if (typeof preId === "string") {
      if (preId.includes(":")) {
        const [preCh, preSq] = preId.split(":");
        const preRef = userRef.collection("progress").doc(preCh).collection("subQuests").doc(preSq);

        const preSnap = await preRef.get();
        if (preSnap.exists && preSnap.data().state === "completed") {
          initialState = "inProgress";
        }
      } else {
        const preRef = userRef.collection("progress").doc(chapterId).collection("subQuests").doc(preId);

        const preSnap = await preRef.get();
        if (preSnap.exists && preSnap.data().state === "completed") {
          initialState = "inProgress";
        }
      }
    } else if (typeof preId === "object" && preId.chapter && preId.sub) {
      const preRef = userRef.collection("progress").doc(preId.chapter).collection("subQuests").doc(preId.sub);

      const preSnap = await preRef.get();
      if (preSnap.exists && preSnap.data().state === "completed") {
        initialState = "inProgress";
      }
    }

    await progressRef.set(
      {
        questId: chapterId,
        subQuestId,
        state: initialState,
        earnedExp: 0,
        attempts: 0,
        perfectClear: false,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    console.log(`✅ User ${userDoc.id} → ${chapterId}/${subQuestId} progress 추가 (state: ${initialState})`);
  }

  return true;
});