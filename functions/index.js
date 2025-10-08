const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

initializeApp();
const db = getFirestore();


// ✅ 유저 문서가 생성될 때: 레벨/경험치 기본값 + progress 초기화
exports.initUserProgress = onDocumentCreated("users/{userId}", async (event) => {
  const userId = event.params.userId;
  const userRef = db.collection("users").doc(userId);

  // 기본 정보 세팅
  await userRef.set({
    level: 1,
    exp: 0,
    lastLogin: FieldValue.serverTimestamp(),
  }, { merge: true });

  // 모든 챕터와 서브퀘스트를 progress에 생성
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


// ✅ progress 완료 → exp/level 업데이트 + 다음 퀘스트 해금
exports.updateUserExpOnClear = onDocumentUpdated("users/{userId}/progress/{chapterId}/subQuests/{subQuestId}", async (event) => {
  const { userId, chapterId, subQuestId } = event.params;
  const before = event.data.before.data();
  const after = event.data.after.data();

  if (!before || !after) return;

  // 클리어 조건 확인
  if (before.state !== "completed" && after.state === "completed") {
    const earnedExp = after.earnedExp || 0;
    console.log(`🎉 SubQuest ${subQuestId} cleared by user ${userId}, earnedExp: ${earnedExp}`);

    // 🔹 경험치/레벨 업데이트
    const userRef = db.collection("users").doc(userId);
    await db.runTransaction(async (t) => {
      const userSnap = await t.get(userRef);
      if (!userSnap.exists) return;

      const user = userSnap.data();
      let exp = user.exp || 0;
      let level = user.level || 1;
      exp += earnedExp;

      // 레벨업 곡선 (예시)
      const expTable = { 1: 100, 2: 120, 3: 160, 4: 200 };
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

    // 🔹 다음 퀘스트 해금
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
});


// ✅ 새로운 Chapter가 quests에 추가될 때 → 모든 유저 progress에 반영
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

    subQuestsSnap.forEach((sqDoc) => {
      const progressRef = userDoc.ref
        .collection("progress").doc(chapterId)
        .collection("subQuests").doc(sqDoc.id);

      batch.set(progressRef, {
        questId: chapterId,
        subQuestId: sqDoc.id,
        state: "locked",
        earnedExp: 0,
        attempts: 0,
        perfectClear: false,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
    });

    await batch.commit();
    console.log(`✅ User ${userDoc.id} → ${chapterId} progress 추가 완료`);
  }
});


// ✅ 새로운 SubQuest가 quests/{chapterId}/subQuests에 추가될 때 → 모든 유저 progress에 반영
exports.onSubQuestCreated = onDocumentCreated("quests/{chapterId}/subQuests/{subQuestId}", async (event) => {
  const { chapterId, subQuestId } = event.params;
  console.log(`🧩 New SubQuest created: ${chapterId}/${subQuestId}`);

  const usersSnap = await db.collection("users").get();
  for (const userDoc of usersSnap.docs) {
    const progressRef = userDoc.ref
      .collection("progress").doc(chapterId)
      .collection("subQuests").doc(subQuestId);

    await progressRef.set({
      questId: chapterId,
      subQuestId,
      state: "locked",
      earnedExp: 0,
      attempts: 0,
      perfectClear: false,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    console.log(`✅ User ${userDoc.id} → ${chapterId}/${subQuestId} progress 추가 완료`);
  }
});
