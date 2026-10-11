import type { APIGatewayProxyEventV2WithJWTAuthorizer, APIGatewayProxyStructuredResultV2 } from 'aws-lambda';
import { GetCommand } from '@aws-sdk/lib-dynamodb';
import { db, keys, tableName, type UserProfile } from '../lib/db.js';
import { error, json } from '../lib/http.js';

export type ApiEvent = APIGatewayProxyEventV2WithJWTAuthorizer;
type Handler = (event: ApiEvent) => Promise<APIGatewayProxyStructuredResultV2>;

// The user ID always comes from the verified token, never from the request.
export function userIdFrom(event: ApiEvent): string | undefined {
  const sub = event.requestContext.authorizer?.jwt?.claims?.sub;
  return typeof sub === 'string' && sub.length > 0 ? sub : undefined;
}

const health: Handler = async () =>
  json(200, { status: 'ok', service: 'secure-captures', version: process.env.APP_VERSION ?? 'dev' });

const getMe: Handler = async (event) => {
  const userId = userIdFrom(event);
  if (!userId) return error(401, 'unauthorized', 'Sign in to use this endpoint.');

  const result = await db.send(
    new GetCommand({ TableName: tableName(), Key: { pk: keys.user(userId), sk: keys.profile } }),
  );
  const profile = result.Item as UserProfile | undefined;
  if (!profile) return error(404, 'profile_not_found', 'No profile exists for this account yet.');

  return json(200, {
    userId: profile.userId,
    email: profile.email,
    createdAt: profile.createdAt,
    photoCount: profile.photoCount,
    bytesStored: profile.bytesStored,
  });
};

// Keys are API Gateway route keys: "<METHOD> <path>".
export const routes: Record<string, Handler> = {
  'GET /api/v1/health': health,
  'GET /api/v1/me': getMe,
};
