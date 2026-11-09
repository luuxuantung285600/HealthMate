import { AiPolicy } from '../src/ai-policy.mjs';
import { ApiError } from '../src/protocol.mjs';

export class MemoryStore {
  constructor() { this.data = new Map(); this.queue = Promise.resolve(); this.calls = 0; this.identityChecks = 0; }
  async assertIdentity(identity) { this.identityChecks++; if (identity.uid !== 'user-a' && identity.uid !== 'user-b') throw new ApiError(401, 'unauthorized'); }
  async transaction(paths, operation) {
    const previous = this.queue; let release; this.queue = new Promise(resolve => { release = resolve; });
    await previous;
    try {
      this.calls++;
      const records = new Map(paths.map(path => [path, structuredClone(this.data.get(path) ?? null)]));
      const result = operation(records);
      for (const write of result.writes ?? []) this.data.set(write.path, structuredClone(write.value));
      if (this.loseAckAt === this.calls) throw new ApiError(503, 'policy_unavailable');
      return result.value;
    } finally { release(); }
  }
}
export function fixture({ now = Date.now, premiumDemo = false, allowTestPurchases = false } = {}) {
  const store = new MemoryStore();
  store.data.set('app_config/runtime', { chatbotEnabled: true, foodScannerEnabled: true, maintenanceMode: false });
  for (const uid of ['user-a', 'user-b']) store.data.set(`users/${uid}`, {
    birthDate: Date.UTC(2000, 0, 1), onboardingCompletedAt: Date.UTC(2026, 0, 1),
  });
  return { store, policy: new AiPolicy(store, { now, premiumDemo, allowTestPurchases }) };
}
