# Project 3: Adversarial ML Defense System

**Duration**: 130 hours

## Goal

Defend production ML models against adversarial attacks:
- Evasion (adversarial inputs at inference)
- Poisoning (training data tampering)
- Model extraction (stealing via queries)
- Membership inference (determining training-set membership)
- Backdoor attacks (trojan triggers)

## Defenses

1. **Adversarial training**: PGD-trained variants of production models
2. **Input validation**: anomaly detection on inference requests
3. **Rate limiting + query budgets**: prevents extraction attacks
4. **Differential privacy**: DP-SGD during training; budget tracking
5. **Backdoor detection**: Neural Cleanse + activation clustering
6. **Watermarking**: prove ownership of extracted models

## Required tools

- [Adversarial Robustness Toolbox](https://github.com/Trusted-AI/adversarial-robustness-toolbox)
- [Foolbox](https://foolbox.readthedocs.io/)
- [PyTorch Opacus](https://opacus.ai/) for DP-SGD
- [TextAttack](https://textattack.readthedocs.io/) for NLP

## Deliverables

- `defenses/` — implementation of each defense
- `attacks/` — implementation of each attack (for testing)
- `benchmark/` — measure defense effectiveness
- `RUNBOOK.md` — when each defense applies
