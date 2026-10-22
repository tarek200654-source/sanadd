import { readFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import test, { after, before, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { Timestamp, collection, doc, getDoc, getDocs, setDoc, writeBatch } from 'firebase/firestore';

const projectId = 'demo-sanad-rules';
let environment;

before(async () => {
  environment = await initializeTestEnvironment({
    projectId,
    firestore: {
      host: process.env.FIRESTORE_EMULATOR_HOST?.split(':')[0] ?? '127.0.0.1',
      port: Number(process.env.FIRESTORE_EMULATOR_HOST?.split(':')[1] ?? 8080),
      rules: await readFile(resolve(process.cwd(), '../../firestore.rules'), 'utf8'),
    },
  });
});

after(async () => environment?.cleanup());

beforeEach(async () => environment.clearFirestore());

const profile = (username = 'mona_1') => ({
  name: 'منى أحمد',
  email: 'mona@example.com',
  role: 'patient',
  username,
  firstName: 'منى',
  lastName: 'أحمد',
  country: 'مصر',
  region: 'القاهرة',
  address: 'شارع 1',
  phoneNumber: '+201012345678',
  createdAt: Timestamp.now(),
});

async function createAccount(uid, username = 'mona_1', values = profile(username)) {
  const db = environment
    .authenticatedContext(uid, { email: 'mona@example.com' })
    .firestore();
  const batch = writeBatch(db);
  batch.set(doc(db, `users/${uid}`), values);
  batch.set(doc(db, `usernames/${username.toLowerCase()}`), { reserved: true });
  await batch.commit();
}

test('permits a matching profile and username reservation in one atomic write', async () => {
  await assertSucceeds(createAccount('uid-1'));
});

test('prevents another account from reserving the same username with different casing', async () => {
  await createAccount('uid-1');
  await assertFails(createAccount('uid-2', 'Mona_1'));
});

test('allows single reservation lookups but denies reservation enumeration', async () => {
  await createAccount('uid-1');
  const unauthenticated = environment.unauthenticatedContext().firestore();
  const reservation = await assertSucceeds(
    getDoc(doc(unauthenticated, 'usernames/mona_1')),
  );
  assert.deepEqual(reservation.data(), { reserved: true });
  await assertFails(getDocs(collection(unauthenticated, 'usernames')));
});

test('keeps profiles private to their owner', async () => {
  await createAccount('uid-1');
  const otherUser = environment
    .authenticatedContext('uid-2', { email: 'other@example.com' })
    .firestore();
  await assertFails(getDoc(doc(otherUser, 'users/uid-1')));
});

test('prevents owners from changing their role or username', async () => {
  await createAccount('uid-1');
  const db = environment
    .authenticatedContext('uid-1', { email: 'mona@example.com' })
    .firestore();
  await assertFails(setDoc(doc(db, 'users/uid-1'), { ...profile(), role: 'caregiver' }));
  await assertFails(setDoc(doc(db, 'users/uid-1'), { ...profile('other_1') }));
});

test('rejects profile writes without a matching username reservation', async () => {
  const db = environment
    .authenticatedContext('uid-1', { email: 'mona@example.com' })
    .firestore();
  await assertFails(setDoc(doc(db, 'users/uid-1'), profile()));
});

test('requires the profile email to match the authenticated email claim', async () => {
  const db = environment
    .authenticatedContext('uid-1', { email: 'verified@example.com' })
    .firestore();
  const batch = writeBatch(db);
  batch.set(doc(db, 'users/uid-1'), profile());
  batch.set(doc(db, 'usernames/mona_1'), { reserved: true });
  await assert.rejects(batch.commit());
});
