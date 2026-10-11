import { beforeEach, describe, expect, it, vi } from 'vitest';
import { mockClient } from 'aws-sdk-client-mock';
import { DynamoDBDocumentClient, PutCommand } from '@aws-sdk/lib-dynamodb';
import { ConditionalCheckFailedException } from '@aws-sdk/client-dynamodb';
import type { PostConfirmationTriggerEvent } from 'aws-lambda';
import { handler } from '../src/triggers/postConfirmation.js';

const ddb = mockClient(DynamoDBDocumentClient);

function event(triggerSource: PostConfirmationTriggerEvent['triggerSource']): PostConfirmationTriggerEvent {
  return {
    version: '1',
    region: 'eu-west-2',
    userPoolId: 'eu-west-2_pool',
    userName: 'abc',
    triggerSource,
    callerContext: { awsSdkVersion: '3', clientId: 'client' },
    request: { userAttributes: { sub: 'abc', email: 'george@example.com' } },
    response: {},
  };
}

beforeEach(() => {
  ddb.reset();
  process.env.TABLE_NAME = 'secure-captures-test';
  vi.spyOn(console, 'log').mockImplementation(() => {});
});

describe('post-confirmation trigger', () => {
  it('creates the profile after sign-up and returns the event to Cognito', async () => {
    ddb.on(PutCommand).resolves({});
    const input = event('PostConfirmation_ConfirmSignUp');

    const result = await handler(input);

    expect(result).toBe(input);
    const put = ddb.commandCalls(PutCommand)[0]?.args[0].input;
    expect(put?.Item).toMatchObject({
      pk: 'USER#abc',
      sk: 'PROFILE',
      userId: 'abc',
      email: 'george@example.com',
      photoCount: 0,
      bytesStored: 0,
    });
    expect(put?.ConditionExpression).toBe('attribute_not_exists(pk)');
  });

  it('treats an existing profile as success, since Cognito retries triggers', async () => {
    ddb.on(PutCommand).rejects(new ConditionalCheckFailedException({ message: 'exists', $metadata: {} }));
    await expect(handler(event('PostConfirmation_ConfirmSignUp'))).resolves.toBeDefined();
  });

  it('does nothing after a password reset', async () => {
    await handler(event('PostConfirmation_ConfirmForgotPassword'));
    expect(ddb.commandCalls(PutCommand)).toHaveLength(0);
  });

  it('fails on other database errors so Cognito reports them', async () => {
    ddb.on(PutCommand).rejects(new Error('throttled'));
    await expect(handler(event('PostConfirmation_ConfirmSignUp'))).rejects.toThrow('throttled');
  });
});
