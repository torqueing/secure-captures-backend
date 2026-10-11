import type { APIGatewayProxyStructuredResultV2 } from 'aws-lambda';

const baseHeaders = {
  'content-type': 'application/json',
  'cache-control': 'no-store',
};

export function json(statusCode: number, body: unknown): APIGatewayProxyStructuredResultV2 {
  return { statusCode, headers: baseHeaders, body: JSON.stringify(body) };
}

export function error(statusCode: number, code: string, message: string): APIGatewayProxyStructuredResultV2 {
  return json(statusCode, { error: { code, message } });
}
