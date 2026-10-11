import type { APIGatewayProxyEventV2WithJWTAuthorizer } from 'aws-lambda';

export function apiEvent(
  method: string,
  path: string,
  claims?: Record<string, string>,
): APIGatewayProxyEventV2WithJWTAuthorizer {
  return {
    version: '2.0',
    routeKey: '$default',
    rawPath: path,
    rawQueryString: '',
    headers: {},
    isBase64Encoded: false,
    requestContext: {
      accountId: '123456789012',
      apiId: 'api',
      domainName: 'example.com',
      domainPrefix: 'example',
      http: { method, path, protocol: 'HTTP/1.1', sourceIp: '127.0.0.1', userAgent: 'test' },
      requestId: 'req-1',
      routeKey: '$default',
      stage: '$default',
      time: '',
      timeEpoch: 0,
      authorizer: { principalId: '', integrationLatency: 0, jwt: { claims: claims ?? {}, scopes: [] } },
    },
  } as APIGatewayProxyEventV2WithJWTAuthorizer;
}
