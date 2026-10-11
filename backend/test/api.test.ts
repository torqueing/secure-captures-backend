import { beforeEach, describe, expect, it, vi } from 'vitest';
import { mockClient } from 'aws-sdk-client-mock';
import { DynamoDBDocumentClient, GetCommand } from '@aws-sdk/lib-dynamodb';
import { handler } from '../src/api/handler.js';
import { apiEvent } from './helpers.js';

const ddb = mockClient(DynamoDBDocumentClient);

beforeEach(() => {
  ddb.reset();
  process.env.TABLE_NAME = 'secure-captures-test';
  vi.spyOn(console, 'log').mockImplementation(() => {});
  vi.spyOn(console, 'error').mockImplementation(() => {});
});

const body = (res: { body?: string }) => JSON.parse(res.body ?? '{}');

describe('GET /api/v1/health', () => {
  it('returns ok without a token', async () => {
    const res = await handler(apiEvent('GET', '/api/v1/health'));
    expect(res.statusCode).toBe(200);
    expect(body(res).status).toBe('ok');
    expect(res.headers?.['cache-control']).toBe('no-store');
  });

  it('ignores a trailing slash', async () => {
    const res = await handler(apiEvent('GET', '/api/v1/health/'));
    expect(res.statusCode).toBe(200);
  });
});

describe('GET /api/v1/me', () => {
  it('returns the profile for the signed-in user only', async () => {
    ddb.on(GetCommand).resolves({
      Item: {
        pk: 'USER#abc',
        sk: 'PROFILE',
        userId: 'abc',
        email: 'george@example.com',
        createdAt: '2026-10-11T00:00:00.000Z',
        photoCount: 0,
        bytesStored: 0,
      },
    });

    const res = await handler(apiEvent('GET', '/api/v1/me', { sub: 'abc' }));

    expect(res.statusCode).toBe(200);
    expect(body(res)).toEqual({
      userId: 'abc',
      email: 'george@example.com',
      createdAt: '2026-10-11T00:00:00.000Z',
      photoCount: 0,
      bytesStored: 0,
    });
    const input = ddb.commandCalls(GetCommand)[0]?.args[0].input;
    expect(input?.Key).toEqual({ pk: 'USER#abc', sk: 'PROFILE' });
    expect(input?.TableName).toBe('secure-captures-test');
  });

  it('rejects a request with no user in the token', async () => {
    const res = await handler(apiEvent('GET', '/api/v1/me'));
    expect(res.statusCode).toBe(401);
    expect(body(res).error.code).toBe('unauthorized');
    expect(ddb.commandCalls(GetCommand)).toHaveLength(0);
  });

  it('returns 404 when the profile does not exist', async () => {
    ddb.on(GetCommand).resolves({});
    const res = await handler(apiEvent('GET', '/api/v1/me', { sub: 'abc' }));
    expect(res.statusCode).toBe(404);
    expect(body(res).error.code).toBe('profile_not_found');
  });

  it('hides internal errors behind a 500', async () => {
    ddb.on(GetCommand).rejects(new Error('table missing'));
    const res = await handler(apiEvent('GET', '/api/v1/me', { sub: 'abc' }));
    expect(res.statusCode).toBe(500);
    expect(body(res).error.message).not.toContain('table missing');
  });
});

describe('unknown routes', () => {
  it('returns 404 with the error shape', async () => {
    const res = await handler(apiEvent('POST', '/api/v1/nothing'));
    expect(res.statusCode).toBe(404);
    expect(body(res).error.code).toBe('not_found');
  });
});
