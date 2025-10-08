const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

const db = admin.firestore();

// ✅ 유저 문서가 생성될 때: 레벨/경험치 기본값 + progress 초기화
exports.initUserProgress = functions.firestore
  .document("users/{userId}")
  .onCreate(async (snap, context) => {
    const userId = context.params.userId;
    const userRef = db.collection("users").doc(userId);

    // ✅ update 대신 set + merge (문서 없을 때도 안전)
    await userRef.set({
      level: 1,
      exp: 0,
      lastLogin: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

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
      console.log(`✅ ${chapterDoc.id} progress 초기화 완료`);
    }

    console.log(`✅ User ${userId} initialized with level/exp and all progress`);
    return true;
  });


// ✅ progress 완료 → exp/level 업데이트
exports.updateUserExpOnClear = functions.firestore
  .document("users/{userId}/progress/{subQuestId}")
  .onUpdate(async (change, context) => {
    const { userId, subQuestId } = context.params;
    const before = change.before.data();
    const after = change.after.data();
    const db = admin.firestore();

    // ✅ 클리어 조건 확인
    if (before.state !== "completed" && after.state === "completed") {
      const earnedExp = after.earnedExp || 0;
      console.log(`🎉 SubQuest ${subQuestId} cleared by user ${userId}, earnedExp: ${earnedExp}`);

      // 🔹 경험치/레벨 업데이트 (기존 로직 유지)
      const userRef = db.collection("users").doc(userId);
      await db.runTransaction(async (t) => {
        const userSnap = await t.get(userRef);
        if (!userSnap.exists) return;

        const user = userSnap.data();
        let exp = user.exp || 0;
        let level = user.level || 1;
        exp += earnedExp;

        // 레벨업 곡선 계산 (간단 예시)
        const expTable = { 1: 100, 2: 120, 3: 160, 4: 200 }; // … 실제 테이블 넣기
        while (exp >= (expTable[level] || Infinity)) {
          exp -= expTable[level];
          level++;
        }

        t.update(userRef, {
          exp,
          level,
          lastLogin: admin.firestore.FieldValue.serverTimestamp()
        });
      });

      // 🔹 다음 퀘스트 해금
      const subQuestRef = db.collection("quests")
        .doc(after.questId)               // progress 문서에 questId 저장돼 있어야 함
        .collection("subQuests");

      const snapshot = await subQuestRef.where("preId", "==", subQuestId).get();
      if (!snapshot.empty) {
        const batch = db.batch();
        snapshot.forEach((doc) => {
          const nextSubQuestId = doc.id;
          const userProgressRef = db.collection("users")
            .doc(userId)
            .collection("progress")
            .doc(nextSubQuestId);

          batch.update(userProgressRef, {
            state: "inProgress",
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          });
        });
        await batch.commit();
        console.log(`🔓 다음 퀘스트 해금 완료 for user ${userId}`);
      }
    }
  });
