import type { PostConfirmationTriggerEvent } from 'aws-lambda';
import { PutCommand } from '@aws-sdk/lib-dynamodb';
import { ConditionalCheckFailedException } from '@aws-sdk/client-dynamodb';
import { db, keys, tableName, type UserProfile } from '../lib/db.js';
import { logger } from '../lib/logger.js';

// Creates the user's profile record once Cognito has confirmed their email code.
export async function handler(event: PostConfirmationTriggerEvent): Promise<PostConfirmationTriggerEvent> {
  // The same trigger also fires after a password reset; only sign-up creates a profile.
  if (event.triggerSource !== 'PostConfirmation_ConfirmSignUp') return event;

  const userId = event.request.userAttributes.sub;
  const email = event.request.userAttributes.email;
  if (!userId || !email) throw new Error('Confirmed user is missing sub or email');

  const profile: UserProfile = {
    pk: keys.user(userId),
    sk: keys.profile,
    userId,
    email,
    createdAt: new Date().toISOString(),
    photoCount: 0,
    bytesStored: 0,
  };

  try {
    await db.send(
      new PutCommand({
        TableName: tableName(),
        Item: profile,
        ConditionExpression: 'attribute_not_exists(pk)',
      }),
    );
    logger.info('user profile created', { userId });
  } catch (err) {
    // Cognito retries triggers, so an existing profile is expected and fine.
    if (err instanceof ConditionalCheckFailedException) {
      logger.info('user profile already exists', { userId });
    } else {
      throw err;
    }
  }
  return event;
}
