const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

initializeApp();
const db = getFirestore();

// ✅ 유저 생성 시 기본 세팅 + progress 초기화
exports.initUserProgress = onDocumentCreated("users/{userId}", async (event) => {
  const userId = event.params.userId;
  const userRef = db.collection("users").doc(userId);

  // 기본 정보
  await userRef.set({
    level: 1,
    exp: 0,
    lastLogin: FieldValue.serverTimestamp(),
  }, { merge: true });

  // 모든 챕터/서브퀘스트 progress 생성
  const chaptersSnap = await db.collection("quests").get();

  for (const chapterDoc of chaptersSnap.docs) {
    const subQuestsSnap = await chapterDoc.ref
      .collection("subQuests")
      .orderBy("order")
      .get();

    let index = 0;
    const batch = db.batch();

    subQuestsSnap.forEach((sqDoc) => {
      const progressRef = userRef
        .collection("progress").doc(chapterDoc.id)
        .collection("subQuests").doc(sqDoc.id);

      let state = "locked";
      if (chapterDoc.id === "ch1" && index === 0) {
        state = "inProgress";
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

// ✅ progress 완료 → exp/level 업데이트 + 챕터 보상(1회) + 다음 퀘스트 해금
exports.updateUserExpOnClear = onDocumentUpdated(
  "users/{userId}/progress/{chapterId}/subQuests/{subQuestId}",
  async (event) => {
    const { userId, chapterId, subQuestId } = event.params;
    const before = event.data.before.data();
    const after = event.data.after.data();

    if (!before || !after) return;

    // 경험치 증가분 계산
    const beforeExp = before.earnedExp || 0;
    const afterExp = after.earnedExp || 0;
    const deltaExp = afterExp - beforeExp;

    if (deltaExp <= 0) {
      console.log(`ℹ️ 경험치 증가 없음: ${subQuestId}`);
      return;
    }

    console.log(`🎉 SubQuest ${subQuestId} → +${deltaExp} exp for user ${userId}`);

    const userRef = db.collection("users").doc(userId);

    // 🔹 1) 서브퀘스트 경험치 반영
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
        16: 2840, 17: 3550, 18: 4440, 19: 5550
      };

      while (exp >= (expTable[level] || Infinity)) {
        exp -= expTable[level];
        level++;
      }

      t.update(userRef, {
        exp,
        level,
        lastLogin: FieldValue.serverTimestamp()
      });
    });

    // 🔹 2) 챕터 전체 클리어 보상 체크 (중복 방지)
    const chapterProgressRef = db.collection("users")
      .doc(userId)
      .collection("progress")
      .doc(chapterId);

    const chapterSnap = await chapterProgressRef.get();
    if (chapterSnap.exists && chapterSnap.data().chapterBonusGranted) {
      console.log(`⚠️ Chapter ${chapterId} 보너스 이미 지급됨`);
    } else {
      const subQuestsSnap = await chapterProgressRef.collection("subQuests").get();
      const allCompleted = subQuestsSnap.docs.every(doc => doc.data().state === "completed");

      if (allCompleted) {
        const bonusPercent = 30; // 고정
        console.log(`🏆 Chapter ${chapterId} 완료 보상 지급 (${bonusPercent}%)`);

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
            16: 2840, 17: 3550, 18: 4440, 19: 5550
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

    // 🔹 3) 다음 서브퀘스트 해금
    const subQuestRef = db.collection("quests")
      .doc(after.questId)
      .collection("subQuests");

    const snapshot = await subQuestRef.where("preId", "==", subQuestId).get();
    if (!snapshot.empty) {
      const batch = db.batch();
      snapshot.forEach((doc) => {
        const nextSubQuestId = doc.id;
        const userProgressRef = db.collection("users")
          .doc(userId)
          .collection("progress").doc(chapterId)
          .collection("subQuests").doc(nextSubQuestId);

        batch.update(userProgressRef, {
          state: "inProgress",
          updatedAt: FieldValue.serverTimestamp()
        });
      });
      await batch.commit();
      console.log(`🔓 다음 퀘스트 해금 완료 for user ${userId}`);
    }
  }
);

// ✅ 새로운 Chapter가 추가될 때 모든 유저 progress 생성
exports.onChapterCreated = onDocumentCreated("quests/{chapterId}", async (event) => {
  const chapterId = event.params.chapterId;
  console.log(`📘 New Chapter created: ${chapterId}`);

  const subQuestsSnap = await event.data.ref.collection("subQuests").orderBy("order").get();
  if (subQuestsSnap.empty) {
    console.log("⚠️ subQuests 없음 → progress 생성 안 함");
    return;
  }

  const usersSnap = await db.collection("users").get();
  for (const userDoc of usersSnap.docs) {
    const batch = db.batch();
    let index = 0;

    subQuestsSnap.forEach((sqDoc) => {
      let state = "locked";
      if (index === 0 && chapterId === "ch1") {
        state = "inProgress";
      }

      const progressRef = userDoc.ref
        .collection("progress").doc(chapterId)
        .collection("subQuests").doc(sqDoc.id);

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
    });

    await batch.commit();
    console.log(`✅ User ${userDoc.id} → ${chapterId} progress 추가 완료`);
  }
});

// ✅ 새로운 SubQuest가 추가될 때 모든 유저 progress 생성 (preId 조건 반영)
exports.onSubQuestCreated = onDocumentCreated("quests/{chapterId}/subQuests/{subQuestId}", async (event) => {
  const { chapterId, subQuestId } = event.params;
  console.log(`🧩 New SubQuest created: ${chapterId}/${subQuestId}`);

  const newSubQuestData = event.data.data();
  const preId = newSubQuestData.preId || null;

  const usersSnap = await db.collection("users").get();
  for (const userDoc of usersSnap.docs) {
    const progressRef = userDoc.ref
      .collection("progress").doc(chapterId)
      .collection("subQuests").doc(subQuestId);

    let initialState = "locked";

    if (!preId) {
      // preId가 없으면 바로 오픈
      initialState = "inProgress";
    } else {
      const preQuestRef = userDoc.ref
        .collection("progress").doc(chapterId)
        .collection("subQuests").doc(preId);

      const preQuestSnap = await preQuestRef.get();
      if (preQuestSnap.exists && preQuestSnap.data().state === "completed") {
        initialState = "inProgress";
      }
    }

    await progressRef.set({
      questId: chapterId,
      subQuestId,
      state: initialState,
      earnedExp: 0,
      attempts: 0,
      perfectClear: false,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    console.log(`✅ User ${userDoc.id} → ${chapterId}/${subQuestId} progress 추가 완료 (state: ${initialState})`);
  }
});
