const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// runs every Sunday at midnight UTC
exports.resetTrendingScores = functions.pubsub
  .schedule('0 0 * * 0')
  .timeZone('UTC')
  .onRun(async (context) => {
    const db = admin.firestore();
    const trendingRef = db.collection('trending');
    
    try {
      const snapshot = await trendingRef.get();
      
      if (snapshot.empty) {
        console.log('No trending documents to delete');
        return null;
      }
      
      // delete all documents in batches (max 500 per batch)
      const batchSize = 500;
      const batches = [];
      let batch = db.batch();
      let count = 0;
      
      snapshot.docs.forEach((doc) => {
        batch.delete(doc.ref);
        count++;
        
        if (count === batchSize) {
          batches.push(batch.commit());
          batch = db.batch();
          count = 0;
        }
      });
      
      // commit remaining documents
      if (count > 0) {
        batches.push(batch.commit());
      }
      
      await Promise.all(batches);
      
      console.log(`Successfully reset ${snapshot.size} trending scores`);
      return null;
      
    } catch (error) {
      console.error('Error resetting trending scores:', error);
      throw error;
    }
  });