import { initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";

initializeApp();

const db = getFirestore();
const categories = new Set(["Support", "Stories", "Self-care", "Daily wins"]);
const blockedTerms = [
  "kill yourself",
  "hurt yourself",
  "self harm instructions",
  "buy drugs",
  "child sexual",
  "doxx",
  "credit card",
];

type CallableRequest = { auth?: { uid: string } | null; data?: Record<string, unknown> };

function requireAuth(request: CallableRequest): string {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Sign in to join the community.");
  }
  return request.auth.uid;
}

function textValue(value: unknown, field: string, maxLength: number): string {
  if (typeof value !== "string") {
    throw new HttpsError("invalid-argument", `${field} is required.`);
  }
  const trimmed = value.trim();
  if (!trimmed || trimmed.length > maxLength) {
    throw new HttpsError("invalid-argument", `${field} has an invalid length.`);
  }
  return trimmed;
}

function moderate(text: string) {
  const normalized = text.toLowerCase().replace(/\s+/g, " ");
  const matchedTerms = blockedTerms.filter((term) => normalized.includes(term));
  const hasRepeatedLinks = (normalized.match(/https?:\/\//g) ?? []).length > 2;
  return {
    flagged: matchedTerms.length > 0 || hasRepeatedLinks,
    categories: {
      harmfulLanguage: matchedTerms.length > 0,
      spam: hasRepeatedLinks,
    },
    matchedTerms,
  };
}

export const createPost = onCall(async (request) => {
    const uid = requireAuth(request);
    const body = textValue(request.data?.body, "body", 2000);
    const category = textValue(request.data?.category, "category", 40);
    if (!categories.has(category)) {
      throw new HttpsError("invalid-argument", "Unknown support space.");
    }

    const moderation = moderate(body);
    const status = moderation.flagged ? "needs_review" : "approved";
    const reference = db.collection("communityPosts").doc();
    await reference.set({
      body,
      category,
      authorId: uid,
      anonymousName: "Anonymous",
      createdAt: FieldValue.serverTimestamp(),
      likedBy: [],
      commentCount: 0,
      status,
      moderation,
    });
    return { id: reference.id, status };
});

export const addComment = onCall(async (request) => {
    const uid = requireAuth(request);
    const postId = textValue(request.data?.postId, "postId", 128);
    const body = textValue(request.data?.body, "body", 1000);
    const postReference = db.collection("communityPosts").doc(postId);
    if (!(await postReference.get()).exists) {
      throw new HttpsError("not-found", "Post not found.");
    }

    const moderation = moderate(body);
    const status = moderation.flagged ? "needs_review" : "approved";
    const commentReference = postReference.collection("comments").doc();
    await db.runTransaction(async (transaction) => {
      transaction.set(commentReference, {
        body,
        authorId: uid,
        anonymousName: "Anonymous",
        createdAt: FieldValue.serverTimestamp(),
        status,
        moderation,
      });
      if (status === "approved") {
        transaction.update(postReference, {
          commentCount: FieldValue.increment(1),
        });
      }
    });
    return { id: commentReference.id, status };
});

export const toggleReaction = onCall(async (request) => {
  const uid = requireAuth(request);
  const postId = textValue(request.data?.postId, "postId", 128);
  const reaction = textValue(request.data?.reaction, "reaction", 20);
  if (reaction !== "like") {
    throw new HttpsError("invalid-argument", "Unsupported reaction.");
  }

  const reference = db.collection("communityPosts").doc(postId);
  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(reference);
    if (!snapshot.exists) {
      throw new HttpsError("not-found", "Post not found.");
    }
    const likedBy = new Set<string>(
      (snapshot.data()?.likedBy as string[] | undefined) ?? [],
    );
    if (likedBy.has(uid)) likedBy.delete(uid);
    else likedBy.add(uid);
    transaction.update(reference, { likedBy: [...likedBy] });
  });
  return { ok: true };
});

export const reportContent = onCall(async (request) => {
  const uid = requireAuth(request);
  const targetType = textValue(request.data?.targetType, "targetType", 20);
  const targetId = textValue(request.data?.targetId, "targetId", 128);
  const reason = textValue(request.data?.reason, "reason", 200);
  if (targetType !== "post" && targetType !== "comment") {
    throw new HttpsError("invalid-argument", "Unsupported report target.");
  }

  await db.collection("communityReports").add({
    targetType,
    targetId,
    reporterId: uid,
    reason,
    status: "pending",
    createdAt: FieldValue.serverTimestamp(),
  });
  return { ok: true };
});
