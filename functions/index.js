const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// ✅ 유저 문서가 Firestore에 생성될 때 실행
exports.initUserProgress = functions.firestore
  .document("users/{userId}")
  .onCreate(async (snap, context) => {
    const userId = context.params.userId;
    const db = admin.firestore();
    const userRef = db.collection("users").doc(userId);

    // ✅ 레벨 / 경험치 기본값 추가
    await userRef.update({
      level: 1,
      exp: 0,
      lastLogin: admin.firestore.FieldValue.serverTimestamp(),
    });

    // ✅ quests 전체를 돌면서 progress 생성
    const chaptersSnap = await db.collection("quests").get();

    for (const chapterDoc of chaptersSnap.docs) {
      const subQuestsSnap = await chapterDoc.ref
        .collection("subQuests")
        .orderBy("order")
        .get();

      let index = 0;
      const batch = db.batch();

      subQuestsSnap.forEach((sqDoc) => {
        const progressRef = userRef.collection("progress").doc(sqDoc.id);

        // 기본 상태는 locked, ch1-sq1만 inProgress
        let state = "locked";
        if (chapterDoc.id === "ch1" && index === 0) {
          state = "inProgress";
        }

        batch.set(progressRef, {
          questId: chapterDoc.id,
          subQuestId: sqDoc.id,
          state: state,
          earnedExp: 0,
          attempts: 0,
          perfectClear: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        index++;
      });

      await batch.commit();
    }

    console.log(`✅ User ${userId} initialized with level/exp and all progress`);
    return true;
  });
