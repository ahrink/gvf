import numpy as np
from dataclasses import dataclass
from datetime import datetime, timedelta
import hashlib

@dataclass
class Parallel:
    """Represents one of 8 operational parallels"""
    name: str
    baseline_weight: float
    state: float
    velocity: float
    acceleration: float
    lambda_coeff: float
    mu_coeff: float

class AHRMagnumOpus:
    def __init__(self, operational_capacity=100.0):
        self.operational_capacity = operational_capacity
        self.capital_reserve = operational_capacity * 0.5
        self.cycle_length = 7  # days
        self.parallels = self._init_parallels()
        self.history = []

    def _init_parallels(self):
        """Initialize 8 operational parallels"""
        names = ["Legal", "Economic", "Technical", "Operational",
                 "Geopolitical", "Philosophical", "Cultural", "Researcher"]
        parallels = []
        for i, name in enumerate(names):
            parallels.append(Parallel(
                name=name,
                baseline_weight=1.0 / 8,
                state=np.random.uniform(0.7, 1.0),
                velocity=np.random.uniform(-0.05, 0.05),
                acceleration=np.random.uniform(-0.01, 0.01),
                lambda_coeff=0.3,
                mu_coeff=0.1
            ))
        return parallels

    def morphing_score(self, parallel: Parallel, t: float) -> float:
        """Calculate M_i(t) for a single parallel"""
        return (parallel.baseline_weight * parallel.state +
                parallel.lambda_coeff * parallel.velocity +
                parallel.mu_coeff * parallel.acceleration)

    def phase_alignment(self, p1: Parallel, p2: Parallel, t: float) -> float:
        """Calculate phase offset θ_ij between two parallels"""
        phase_drift_1 = np.sin(2 * np.pi * t / self.cycle_length)
        phase_drift_2 = np.sin(2 * np.pi * t / self.cycle_length + np.pi / 4)
        return np.cos(phase_drift_1 - phase_drift_2)

    def burning_power_z(self, t: float) -> float:
        """Calculate Z(t) — coherence score"""
        morphing_scores = [self.morphing_score(p, t) for p in self.parallels]

        coherence_sum = 0.0
        for i in range(len(self.parallels)):
            for j in range(len(self.parallels)):
                theta_ij = self.phase_alignment(self.parallels[i], self.parallels[j], t)
                coherence_sum += morphing_scores[i] * morphing_scores[j] * theta_ij

        return np.sqrt(max(coherence_sum, 0.0))

    def fibonacci_allocation(self):
        """Calculate Fibonacci-based budget allocation"""
        phi = (1 + np.sqrt(5)) / 2
        allocations = {}
        total = 0.0

        for i, parallel in enumerate(self.parallels[:-1]):  # 7 operational parallels
            budget = (phi ** (-i)) * self.operational_capacity
            allocations[parallel.name] = budget
            total += budget

        return allocations

    def reserve_ratio(self) -> float:
        """Calculate capital reserve ratio"""
        return self.capital_reserve / self.operational_capacity

    def system_state(self, z: float) -> str:
        """Determine system state based on Z and reserve ratio"""
        reserve = self.reserve_ratio()

        if z > 0 and reserve > 0.30:
            return "EXPAND"
        elif z <= 0 or reserve <= 0.30:
            return "PRESERVE"
        elif z < -0.5 and reserve < 0.15:
            return "CONTRACT"
        else:
            return "STABLE"

    def tid_timestamp(self) -> str:
        """Generate cryptographic tID timestamp"""
        now = datetime.now().isoformat()
        hash_obj = hashlib.sha256(now.encode())
        return hash_obj.hexdigest()[:16]

    def step(self, t: float):
        """Execute one time step"""
        # Update parallel dynamics
        for parallel in self.parallels:
            parallel.state += parallel.velocity
            parallel.velocity += parallel.acceleration
            parallel.acceleration = np.random.uniform(-0.01, 0.01)
            parallel.state = np.clip(parallel.state, 0.0, 1.0)

        # Calculate Z
        z = self.burning_power_z(t)

        # Get allocations
        allocations = self.fibonacci_allocation()

        # Determine state
        state = self.system_state(z)

        # Adjust capital based on state
        if state == "EXPAND":
            self.capital_reserve *= 1.02
        elif state == "CONTRACT":
            self.capital_reserve *= 0.95

        # Record snapshot
        snapshot = {
            "timestamp": self.tid_timestamp(),
            "time": t,
            "z_score": z,
            "reserve_ratio": self.reserve_ratio(),
            "system_state": state,
            "allocations": allocations,
            "parallel_states": {p.name: p.state for p in self.parallels}
        }

        self.history.append(snapshot)
        return snapshot

    def run_cycle(self, cycles=7):
        """Run a complete 7-day cycle"""
        print("=" * 80)
        print("AHR MAGNUM OPUS — LIVE PROTOTYPE")
        print("=" * 80)

        for day in range(cycles):
            snapshot = self.step(day)
            print(f"\n[Day {day + 1}] tID: {snapshot['timestamp']}")
            print(f"  Z (Burning Power):     {snapshot['z_score']:.4f}")
            print(f"  Reserve Ratio:         {snapshot['reserve_ratio']:.4f}")
            print(f"  System State:          {snapshot['system_state']}")
            print(f"  Parallel States:")
            for name, state in snapshot['parallel_states'].items():
                print(f"    - {name:15s}: {state:.4f}")

        print("\n" + "=" * 80)
        print("CYCLE COMPLETE")
        print("=" * 80)

# Execute
if __name__ == "__main__":
    opus = AHRMagnumOpus(operational_capacity=100.0)
    opus.run_cycle(cycles=7)
