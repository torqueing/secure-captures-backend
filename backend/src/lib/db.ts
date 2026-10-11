import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient } from '@aws-sdk/lib-dynamodb';

export const db = DynamoDBDocumentClient.from(new DynamoDBClient({}), {
  marshallOptions: { removeUndefinedValues: true },
});

export function tableName(): string {
  const name = process.env.TABLE_NAME;
  if (!name) throw new Error('TABLE_NAME is not set');
  return name;
}

// Single-table key layout; see "Data model" in the specification.
export const keys = {
  user: (userId: string) => `USER#${userId}`,
  profile: 'PROFILE',
};

export interface UserProfile {
  pk: string;
  sk: string;
  userId: string;
  email: string;
  createdAt: string;
  photoCount: number;
  bytesStored: number;
}
