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
    newStage: stageFromLevel(reachedLevel), // ✅ reachedLevel 기준
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
        stage : "egg",
        customization: {},
        evolutionLevel: 0,
        evolutionPending: false,
        evolutionToStage: "egg", // 진화 연출용 목표 스테이지(없어도 되지만 UX/데이터 일관성에 좋음)
      },
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
exports.applyEvolutionStageOnPendingCleared = onDocumentUpdated(
  "users/{userId}",
  async (event) => {
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

          // 필요하면 evolutionToStage를 비워도 됩니다.
          // (남겨두면 디버깅/UX에 도움되지만, 혼동될 수 있음)
          evolutionToStage: FieldValue.delete(), // 확정 후 목표값 제거
          evolutionLevel: FieldValue.delete(),   // 확정 후 정리(원치 않으면 삭제 라인 제거)
        },
      },
      { merge: true }
    );

    console.log("✅ Evolution stage applied:", { userId, from: curStage, to: toStage });
    return true;
  }
);

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

    // 현재 subQuest progress ref를 공통으로 사용 (정산 완료 플래그 기록용)
    const subQuestProgressRef = event.data.after.ref; 

    // 이번 업데이트 사이클에서 "정산 완료"를 언제 찍을지 결정하기 위한 플래그
    // - 챕터 보너스까지 있는 케이스는 챕터 트랜잭션 끝난 뒤에만 settled 찍어야 함
    let shouldSettleAfterChapterBonus = false; 

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

    // ----- (B) 챕터 전체 클리어 보너스: 완료 전환 시점에만 검사 -----
    if (becameCompletedNow) {
      const chapterProgressRef = db
        .collection("users")
        .doc(userId)
        .collection("progress")
        .doc(chapterId);

      // 지금 업데이트가 발생한 "해당 서브퀘스트 progress 문서"
      // - 챕터 보너스 지급이 일어난 '결과 화면'에서 이 문서를 읽어
      //   chapterBonusExpGranted를 UI에 표시할 수 있게 됩니다.
      //const subQuestProgressRef = event.data.after.ref;

      const chapterSnap = await chapterProgressRef.get();
      if (chapterSnap.exists && chapterSnap.data().chapterBonusGranted) {
        console.log(`⚠️ Chapter ${chapterId} 보너스 이미 지급됨`);

        // 챕터 보너스가 "이미 지급"된 경우라도,
        // 이 서브퀘스트에 대한 정산 완료 플래그는 찍어줘야 iOS가 진행할 수 있음
        // (서브퀘스트 exp만 있었든/없었든 “정산 완료”로 간주)
        await markRewardSettled(subQuestProgressRef, { settledBy: "chapterBonusAlreadyGranted" }); 

      } else {
        const subQuestsSnap = await chapterProgressRef.collection("subQuests").get();
        const allCompleted =
          subQuestsSnap.docs.length > 0 &&
          subQuestsSnap.docs.every((doc) => doc.data().state === "completed");

        if (allCompleted) {
          // 이 케이스는 "챕터보너스 트랜잭션"까지 끝나야 정산 완료를 찍을 수 있음
          shouldSettleAfterChapterBonus = true; 

          // ============================
          // 챕터 클리어 보상 고정 140 EXP 지급
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

            const expTable = {
              1: 100, 2: 120, 3: 160, 4: 200, 5: 240,
              6: 310, 7: 380, 8: 480, 9: 600, 10: 750,
              11: 930, 12: 1160, 13: 1460, 14: 1820, 15: 2270,
              16: 2840, 17: 3550, 18: 4440, 19: 5550,
            };

            exp += bonusExp;

            // 레벨업 계산 로직은 그대로 유지
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
            // customization.stage 제거 (위 트랜잭션과 동일한 이유)
            // ============================
            const { stage: _legacyStage2, ...customizationWithoutStage2 } = prevCustomization; 

            const payload = {
              exp,
              level,

              character: {
                ...prevCharacter,

                // ✅ [수정] 진화 발생 시 stage를 즉시 바꾸지 않음
                stage: prevCharacter.stage || "egg",

                customization: {
                  ...customizationWithoutStage2,
                },
              },

              // ❌ [삭제] 부모(character) + 자식(character.customization.stage) 동시 지정 충돌
              // "character.customization.stage": FieldValue.delete(), // [삭제]
            };

            if (evo) {
              payload.character.evolutionLevel = evo.reachedLevel;
              payload.character.evolutionPending = true;
              payload.character.evolutionToStage = evo.newStage; // 목표 스테이지 저장
              console.log(`🌟 Evolution! user=${userId} -> ${evo.newStage} (Lv ${evo.reachedLevel})`);
            } else {
              payload.character.stage = desiredStage; // 진화가 없으면 stage 동기화
            }

            // 1) users 업데이트
            t.update(userRef, payload);

            // 2) chapter 보너스 1회 지급 플래그
            t.set(chapterProgressRef, { chapterBonusGranted: true }, { merge: true });

            // 3) "이번 결과 화면"에서 보여줄 챕터 보너스 정보를 subQuest progress 문서에 기록
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

          // 챕터 보너스 트랜잭션까지 끝난 "마지막 순간"에 정산 완료 플래그 기록
          await markRewardSettled(subQuestProgressRef, { settledBy: "chapterBonusGranted" });
        }
      }
    }


    // ----- (C) 다음 서브퀘스트 해금: 완료 전환 시점에만 실행 -----
    if (!becameCompletedNow) {
      console.log("ℹ️ 완료 상태 전환 아님 → 해금/보너스 스킵");

      // 완료 전환이 아닌 경우엔 "정산 완료"를 찍지 않습니다.
      // (보통 결과 화면이 뜨는 케이스가 아니라서)
      return true;
    }

    // 챕터 클리어 보너스가 "발생하지 않은" 완료 전환(일반 클리어)이라면,
    // 이 시점에서 정산 완료를 찍어도 안전합니다.
    // - 서브퀘스트 exp 트랜잭션은 위에서 이미 끝났음(deltaExp > 0이면)
    // - 챕터 보너스는 이 케이스에 없음
    if (!shouldSettleAfterChapterBonus) {
      await markRewardSettled(subQuestProgressRef, { settledBy: "subQuestClearOnly" }); 
    }

    // where() 없이 스캔으로 해금 타겟 찾기
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
 * 새로운 SubQuest가 추가될 때 모든 유저 progress 생성
 *  - preId 조건을 확인하여 초기 state(inProgress/locked) 결정
 *  - 크로스 챕터 preId도 지원
 *  - 기존 문서가 있으면 상태 보존(덮어쓰기 방지)
 *
 * 권장 정책:
 *  - preId는 "chX:sqN"으로 통일
 */
exports.onSubQuestCreated = onDocumentCreated(
  "quests/{chapterId}/subQuests/{subQuestId}",
  async (event) => {
    const { chapterId, subQuestId } = event.params;
    console.log(`🧩 New SubQuest created: ${chapterId}/${subQuestId}`);

    const newSubQuestData = event.data.data();
    const preId = newSubQuestData.preId || null;

    if (
      preId &&
      !isStandardPreId(preId) &&
      !(typeof preId === "string") &&
      !(typeof preId === "object")
    ) {
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