/* eslint-disable no-console */
const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

initializeApp();
const db = getFirestore();

/**
 * ✅ preId 권장 포맷: "chX:sqN"
 * - 예: "ch1:sq7"
 */
function isStandardPreId(preId) {
  return typeof preId === "string" && /^ch\d+:sq\d+$/i.test(preId);
}

/**
 * ✅ 완료 전환 체크
 * - before != completed && after == completed
 */
function didBecomeCompleted(before, after) {
  return before?.state !== "completed" && after?.state === "completed";
}

/**
 * ✅ (중요) 해금 타겟 찾기: where() 절대 사용하지 않고 전부 스캔
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

  const questsSnap = await db.collection("quests").get();

  for (const q of questsSnap.docs) {
    const subSnap = await q.ref.collection("subQuests").get();

    subSnap.forEach((d) => {
      const data = d.data();
      const p = data.preId;

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
 * ✅ 해금 적용(안전)
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

  const refs = [];
  const items = [];
  for (const { nextChapterId, nextSubQuestId } of unique.values()) {
    const ref = userRef
      .collection("progress")
      .doc(nextChapterId)
      .collection("subQuests")
      .doc(nextSubQuestId);

    refs.push(ref);
    items.push({ ref, nextChapterId, nextSubQuestId });
  }

  const snaps = await db.getAll(...refs);
  const batch = db.batch();
  let changed = 0;

  snaps.forEach((snap, idx) => {
    const { ref, nextChapterId, nextSubQuestId } = items[idx];
    const curState = snap.exists ? snap.data().state : null;

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
 * ✅ 유저 생성 시 기본 세팅 + progress 초기화
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
    },
    { merge: true }
  );

  // 모든 챕터/서브퀘스트 progress 생성
  const chaptersSnap = await db.collection("quests").get();

  for (const chapterDoc of chaptersSnap.docs) {
    const subQuestsSnap = await chapterDoc.ref.collection("subQuests").orderBy("order").get();

    let index = 0;
    const batch = db.batch();

    subQuestsSnap.forEach((sqDoc) => {
      const progressRef = userRef
        .collection("progress")
        .doc(chapterDoc.id)
        .collection("subQuests")
        .doc(sqDoc.id);

      let state = "locked";
      if (chapterDoc.id === "ch1" && index === 0) state = "inProgress";

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
 * ✅ progress 업데이트 훅
 *  - EXP/레벨 반영 (earnedExp 증가분만)
 *  - 챕터 완료 보너스 (해당 챕터의 모든 subQuest가 completed일 때, 1회만)
 *  - 다음 서브퀘스트 해금 (state가 completed로 "전환"되는 시점에만)
 *
 * ✅ 중요:
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
        exp += deltaExp;

        const expTable = {
          1: 100, 2: 120, 3: 160, 4: 200, 5: 240,
          6: 310, 7: 380, 8: 480, 9: 600, 10: 750,
          11: 930, 12: 1160, 13: 1460, 14: 1820, 15: 2270,
          16: 2840, 17: 3550, 18: 4440, 19: 5550,
        };

        while (exp >= (expTable[level] || Infinity)) {
          exp -= expTable[level];
          level++;
        }

        t.update(userRef, {
          exp,
          level,
          lastLogin: FieldValue.serverTimestamp(),
        });
      });
    } else {
      console.log(`ℹ️ 경험치 증가 없음: ${chapterId}/${subQuestId}`);
    }

    // 완료 전환 체크
    const becameCompletedNow = didBecomeCompleted(before, after);

    // ----- (B) 챕터 전체 클리어 보너스: 완료 전환 시점에만 검사 -----
    if (becameCompletedNow) {
      const chapterProgressRef = db
        .collection("users")
        .doc(userId)
        .collection("progress")
        .doc(chapterId);

      const chapterSnap = await chapterProgressRef.get();
      if (chapterSnap.exists && chapterSnap.data().chapterBonusGranted) {
        console.log(`⚠️ Chapter ${chapterId} 보너스 이미 지급됨`);
      } else {
        const subQuestsSnap = await chapterProgressRef.collection("subQuests").get();
        const allCompleted =
          subQuestsSnap.docs.length > 0 &&
          subQuestsSnap.docs.every((doc) => doc.data().state === "completed");

        if (allCompleted) {
          const bonusPercent = 30;
          console.log(`🏆 Chapter ${chapterId} 완료 보상 지급 (${bonusPercent}%)`);

          const userRef = db.collection("users").doc(userId);
          await db.runTransaction(async (t) => {
            const userSnap = await t.get(userRef);
            if (!userSnap.exists) return;

            const user = userSnap.data();
            let exp = user.exp || 0;
            let level = user.level || 1;

            const expTable = {
              1: 100, 2: 120, 3: 160, 4: 200, 5: 240,
              6: 310, 7: 380, 8: 480, 9: 600, 10: 750,
              11: 930, 12: 1160, 13: 1460, 14: 1820, 15: 2270,
              16: 2840, 17: 3550, 18: 4440, 19: 5550,
            };

            const needExp = expTable[level] || 100;
            const bonusExp = Math.floor((needExp * bonusPercent) / 100);

            exp += bonusExp;
            while (exp >= (expTable[level] || Infinity)) {
              exp -= expTable[level];
              level++;
            }

            t.update(userRef, { exp, level });
            t.set(chapterProgressRef, { chapterBonusGranted: true }, { merge: true });
          });
        }
      }
    }

    // ----- (C) 다음 서브퀘스트 해금: 완료 전환 시점에만 실행 -----
    if (!becameCompletedNow) {
      console.log("ℹ️ 완료 상태 전환 아님 → 해금/보너스 스킵");
      return true;
    }

    // ✅ where() 없이 스캔으로 해금 타겟 찾기
    let fullKey = `${chapterId}:${subQuestId}`;
    try {
      const res = await findUnlockTargetsByScan({ chapterId, subQuestId });
      fullKey = res.fullKey;

      // preId가 표준이 아닌 애가 있으면 경고(데이터 정리용)
      // (스캔은 호환 처리하므로 당장은 안 깨짐)
      // 표준만 쓰기로 했으니, 점진적으로 DB 정리하시면 됩니다.
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
 * ✅ 새로운 Chapter가 추가될 때 모든 유저 progress 생성
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

    for (const sqDoc of subQuestsSnap.docs) {
      const progressRef = userDoc.ref
        .collection("progress")
        .doc(chapterId)
        .collection("subQuests")
        .doc(sqDoc.id);

      const existed = await progressRef.get();
      if (existed.exists) continue;

      let state = "locked";
      if (index === 0 && chapterId === "ch1") state = "inProgress";

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
 * ✅ 새로운 SubQuest가 추가될 때 모든 유저 progress 생성
 *  - preId 조건을 확인하여 초기 state(inProgress/locked) 결정
 *  - 크로스 챕터 preId도 지원
 *  - 기존 문서가 있으면 상태 보존(덮어쓰기 방지)
 *
 * ✅ 권장 정책:
 *  - preId는 "chX:sqN"으로 통일
 */
exports.onSubQuestCreated = onDocumentCreated(
  "quests/{chapterId}/subQuests/{subQuestId}",
  async (event) => {
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

      const progressRef = userRef
        .collection("progress")
        .doc(chapterId)
        .collection("subQuests")
        .doc(subQuestId);

      const existed = await progressRef.get();
      if (existed.exists) {
        console.log(`↪︎ skip: ${userDoc.id} already has ${chapterId}/${subQuestId}`);
        continue;
      }

      let initialState = "locked";

      if (!preId) {
        // 선행 조건 없으면 바로 오픈
        initialState = "inProgress";
      } else if (typeof preId === "string") {
        if (preId.includes(":")) {
          // 문자열 키 "chX:sqY"
          const [preCh, preSq] = preId.split(":");
          const preRef = userRef
            .collection("progress")
            .doc(preCh)
            .collection("subQuests")
            .doc(preSq);

          const preSnap = await preRef.get();
          if (preSnap.exists && preSnap.data().state === "completed") {
            initialState = "inProgress";
          }
        } else {
          // 레거시: 같은 챕터 내 "sqY" (호환용)
          const preRef = userRef
            .collection("progress")
            .doc(chapterId)
            .collection("subQuests")
            .doc(preId);

          const preSnap = await preRef.get();
          if (preSnap.exists && preSnap.data().state === "completed") {
            initialState = "inProgress";
          }
        }
      } else if (typeof preId === "object" && preId.chapter && preId.sub) {
        // 오브젝트 키 {chapter, sub} (호환용)
        const preRef = userRef
          .collection("progress")
          .doc(preId.chapter)
          .collection("subQuests")
          .doc(preId.sub);

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

      console.log(
        `✅ User ${userDoc.id} → ${chapterId}/${subQuestId} progress 추가 (state: ${initialState})`
      );
    }

    return true;
  }
);
