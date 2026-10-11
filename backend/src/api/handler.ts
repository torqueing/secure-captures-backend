import type { APIGatewayProxyStructuredResultV2 } from 'aws-lambda';
import { error } from '../lib/http.js';
import { logger } from '../lib/logger.js';
import { routes, type ApiEvent } from './routes.js';

// Single entry point for every HTTP route. API Gateway sends the catch-all route key,
// so the handler matches on the actual method and path.
export async function handler(event: ApiEvent): Promise<APIGatewayProxyStructuredResultV2> {
  const method = event.requestContext.http.method;
  const path = event.rawPath.replace(/\/+$/, '') || '/';
  const requestId = event.requestContext.requestId;
  const route = routes[`${method} ${path}`];

  if (!route) {
    logger.info('route not found', { requestId, method, path });
    return error(404, 'not_found', `No route for ${method} ${path}.`);
  }

  try {
    const response = await route(event);
    logger.info('request handled', { requestId, method, path, status: response.statusCode });
    return response;
  } catch (err) {
    logger.error('request failed', {
      requestId,
      method,
      path,
      error: err instanceof Error ? err.message : String(err),
    });
    return error(500, 'internal_error', 'Something went wrong. Try again later.');
  }
}
