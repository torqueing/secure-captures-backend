// Structured JSON logs. Never pass tokens, keys, coordinates or photo bytes in `fields`.
type Level = 'debug' | 'info' | 'warn' | 'error';

function write(level: Level, message: string, fields: Record<string, unknown> = {}): void {
  const line = JSON.stringify({ level, message, time: new Date().toISOString(), ...fields });
  if (level === 'error' || level === 'warn') console.error(line);
  else console.log(line);
}

export const logger = {
  debug: (message: string, fields?: Record<string, unknown>) => write('debug', message, fields),
  info: (message: string, fields?: Record<string, unknown>) => write('info', message, fields),
  warn: (message: string, fields?: Record<string, unknown>) => write('warn', message, fields),
  error: (message: string, fields?: Record<string, unknown>) => write('error', message, fields),
};
