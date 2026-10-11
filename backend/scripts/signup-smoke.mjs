// Milestone 1 check: signs up a new account against a deployed environment, waits for the
// emailed code, confirms it, then calls the public health endpoint.
//
// Usage: node scripts/signup-smoke.mjs <email>
// Reads SC_CLIENT_ID and SC_API_URL (the Terraform outputs android_client_id and api_url).
import {
  CognitoIdentityProviderClient,
  ConfirmSignUpCommand,
  SignUpCommand,
} from '@aws-sdk/client-cognito-identity-provider';
import { randomBytes } from 'node:crypto';
import { createInterface } from 'node:readline/promises';

const email = process.argv[2];
const clientId = process.env.SC_CLIENT_ID;
const apiUrl = process.env.SC_API_URL;
if (!email || !clientId || !apiUrl) {
  console.error('Usage: SC_CLIENT_ID=... SC_API_URL=... node scripts/signup-smoke.mjs <email>');
  process.exit(1);
}

const health = await fetch(new URL('/api/v1/health', apiUrl));
console.log(`GET /api/v1/health -> ${health.status} ${await health.text()}`);

const cognito = new CognitoIdentityProviderClient({ region: 'eu-west-2' });
// Meets the pool's policy: 12+ characters with upper, lower, digit and symbol.
const password = `Sc-${randomBytes(12).toString('base64url')}9a!`;

await cognito.send(
  new SignUpCommand({
    ClientId: clientId,
    Username: email,
    Password: password,
    UserAttributes: [{ Name: 'email', Value: email }],
  }),
);
console.log(`Signed up ${email}. Check that inbox for a 6-digit code.`);

const rl = createInterface({ input: process.stdin, output: process.stdout });
const code = (await rl.question('Code: ')).trim();
rl.close();

await cognito.send(new ConfirmSignUpCommand({ ClientId: clientId, Username: email, ConfirmationCode: code }));
console.log('Email confirmed. The post-confirmation trigger should now have created the profile record.');
console.log(`Temporary password for this test account: ${password}`);
