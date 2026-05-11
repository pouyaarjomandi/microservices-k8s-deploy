// ============================================================
// k6 Load Test - Validates HPA scaling behavior
// ============================================================
// Usage:
//   k6 run tests/k6/load-test.js
//
// Or via the helper script:
//   ./scripts/test-hpa.sh
//
// Watch HPA scale in another terminal:
//   kubectl get hpa -n dev -w
// ============================================================

import http from 'k6/http';
import { check, sleep, group } from 'k6';

// ------------------------------------------------------------
// Test configuration
// ------------------------------------------------------------
export const options = {
  // Three-stage load profile to trigger HPA scale up and down
  stages: [
    { duration: '30s', target: 50  }, // Ramp up to 50 virtual users
    { duration: '3m',  target: 50  }, // Sustained load (HPA should scale up)
    { duration: '30s', target: 0   }, // Ramp down (HPA should scale down later)
  ],

  // Performance thresholds - test fails if these are not met
  thresholds: {
    http_req_failed:   ['rate<0.05'],  // less than 5% errors
    http_req_duration: ['p(95)<2000'], // 95% of requests under 2s
  },
};

// ------------------------------------------------------------
// Base URL - assumes port-forward to localhost:8080
// ------------------------------------------------------------
const BASE_URL = __ENV.BASE_URL || 'http://localhost:8080';

// ------------------------------------------------------------
// Product IDs from Online Boutique catalog
// Used to simulate realistic browsing behavior
// ------------------------------------------------------------
const PRODUCT_IDS = [
  'OLJCESPC7Z',  // Sunglasses
  '66VCHSJNUP',  // Tank Top
  '1YMWWN1N4O',  // Watch
  'L9ECAV7KIM',  // Loafers
  '2ZYFJ3GM2N',  // Hairdryer
  '0PUK6V6EV0',  // Candle Holder
  'LS4PSXUNUM',  // Salt & Pepper Shakers
  '9SIQT8TOJO',  // Bamboo Glass Jar
  '6E92ZMYYFZ',  // Mug
];

const CURRENCIES = ['USD', 'EUR', 'GBP', 'CAD', 'JPY'];

// ------------------------------------------------------------
// Pick a random element from an array
// ------------------------------------------------------------
function randomItem(array) {
  return array[Math.floor(Math.random() * array.length)];
}

// ------------------------------------------------------------
// Main test function - runs once per virtual user iteration
// ------------------------------------------------------------
export default function () {
  // Scenario 1: Browse home page (40% of traffic)
  group('Browse home', () => {
    const res = http.get(`${BASE_URL}/`);
    check(res, {
      'home status is 200':   (r) => r.status === 200,
      'home loads under 1s':  (r) => r.timings.duration < 1000,
    });
  });

  sleep(1);

  // Scenario 2: View a random product (30% of traffic)
  group('View product', () => {
    const productId = randomItem(PRODUCT_IDS);
    const res = http.get(`${BASE_URL}/product/${productId}`);
    check(res, {
      'product status is 200': (r) => r.status === 200,
    });
  });

  sleep(1);

  // Scenario 3: Change currency (15% of traffic)
  group('Change currency', () => {
    const currency = randomItem(CURRENCIES);
    const res = http.post(
      `${BASE_URL}/setCurrency`,
      { currency_code: currency }
    );
    check(res, {
      'currency change ok': (r) => r.status === 200 || r.status === 302,
    });
  });

  sleep(1);

  // Scenario 4: Add to cart (15% of traffic)
  group('Add to cart', () => {
    const productId = randomItem(PRODUCT_IDS);
    const res = http.post(
      `${BASE_URL}/cart`,
      { product_id: productId, quantity: '1' }
    );
    check(res, {
      'add to cart ok': (r) => r.status === 200 || r.status === 302,
    });
  });

  sleep(2);
}

// ------------------------------------------------------------
// Optional: setup function runs once before the test starts
// ------------------------------------------------------------
export function setup() {
  console.log(`Starting load test against ${BASE_URL}`);
  console.log('Watch HPA scaling: kubectl get hpa -n dev -w');

  // Verify the application is reachable before running the test
  const res = http.get(BASE_URL);
  if (res.status !== 200) {
    throw new Error(
      `Application not reachable at ${BASE_URL} (status: ${res.status})`
    );
  }
}

// ------------------------------------------------------------
// Optional: teardown function runs once after the test completes
// ------------------------------------------------------------
export function teardown() {
  console.log('Load test complete.');
  console.log('Check HPA state: kubectl get hpa -n dev');
}