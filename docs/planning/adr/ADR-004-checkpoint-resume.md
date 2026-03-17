# ADR-004: Checkpoint/resume pipeline

## Status
Accepted

## Context
Le pipeline d'analyse (14 phases) peut durer plusieurs heures sur un gros corpus. Un crash (OOM, network timeout, worker restart) ne doit pas obliger a tout reprendre du debut.

## Decision
Implementer un systeme de checkpoint par phase dans `AnalysisJob.current_phase`. Chaque phase nettoie ses resultats partiels avant re-execution et le worker recovery au demarrage re-dispatche les jobs stale.

## Consequences

### Positif
- Tolerance aux pannes : reprise depuis la derniere phase completee
- Recovery automatique au demarrage worker (RUNNING → QUEUED → re-dispatch)
- Chaque phase est idempotente (cleanup avant re-execution)
- Progress tracking precis (pourcentage par phase)

### Negatif
- Complexite du code de cleanup par phase
- Chaque nouvelle phase doit implementer sa logique de cleanup
- Le checkpoint est au niveau phase, pas au niveau item (si une phase crash a mi-chemin, elle repart du debut de la phase)

### Risques
- Si le cleanup est incomplet, des resultats partiels peuvent persister et fausser les phases suivantes
