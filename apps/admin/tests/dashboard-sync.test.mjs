import {test} from 'node:test';
import assert from 'node:assert/strict';
import {startDashboardSync} from '../src/lib/dashboard-sync.ts';

test('refreshes on the interval and return to the dashboard, then cleans up', async t => {
  t.mock.timers.enable({apis:['setInterval']});
  const browser = new EventTarget(), page = new EventTarget();
  page.visibilityState = 'visible';
  let count = 0;
  const stop = startDashboardSync(async () => { count++; }, () => true, browser, page);
  t.mock.timers.tick(30_000);
  await Promise.resolve();
  assert.equal(count, 1);
  browser.dispatchEvent(new Event('focus'));
  await Promise.resolve();
  browser.dispatchEvent(new Event('online'));
  await Promise.resolve();
  assert.equal(count, 3);
  stop();
  t.mock.timers.tick(60_000);
  browser.dispatchEvent(new Event('focus'));
  assert.equal(count, 3);
});

test('skips hidden pages and edits, deduplicates requests, and retries after errors', async t => {
  t.mock.timers.enable({apis:['setInterval']});
  const browser = new EventTarget(), page = new EventTarget();
  page.visibilityState = 'hidden';
  let allowed = true, count = 0, release;
  const stop = startDashboardSync(async () => {
    count++;
    if (count === 1) await new Promise(resolve => { release = resolve; });
    else throw new Error('offline');
  }, () => allowed, browser, page);
  t.mock.timers.tick(30_000);
  assert.equal(count, 0);
  page.visibilityState = 'visible';
  allowed = false;
  page.dispatchEvent(new Event('visibilitychange'));
  assert.equal(count, 0);
  allowed = true;
  page.dispatchEvent(new Event('visibilitychange'));
  browser.dispatchEvent(new Event('focus'));
  t.mock.timers.tick(30_000);
  assert.equal(count, 1);
  release();
  await Promise.resolve(); await Promise.resolve();
  browser.dispatchEvent(new Event('online'));
  await Promise.resolve();
  browser.dispatchEvent(new Event('focus'));
  await Promise.resolve();
  assert.equal(count, 3);
  stop();
});
