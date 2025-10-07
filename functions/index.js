const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// ✅ 가입 시 자동으로 챕터1-서브퀘스트1 progress 문서 생성
exports.initUserProgress = functions.firestore
  .document("users/{userId}")
  .onCreate(async (snap, context) => {
    const userId = context.params.userId;

    const progressRef = admin.firestore()
      .collection("users").doc(userId)
      .collection("progress").doc("sq1");

    await progressRef.set({
      questId: "ch1",
      subQuestId: "sq1",
      state: "inProgress",    // 첫 퀘스트 바로 오픈
      earnedExp: 0,
      attempts: 0,
      perfectClear: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    console.log(`✅ Progress for user ${userId} initialized`);
    return true;
  });
