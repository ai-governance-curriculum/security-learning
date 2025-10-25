#!/bin/bash

# AI Infrastructure Security Engineer Learning Repository Builder
# This script creates the complete repository structure

set -e

BASE_DIR="/home/claude/ai-infrastructure-project/repositories/learning/ai-infra-security-learning"
cd "$BASE_DIR"

echo "Building AI Infrastructure Security Engineer Learning Repository..."

# Create directory structure
mkdir -p .github/workflows
mkdir -p .github/ISSUE_TEMPLATE
mkdir -p lessons
mkdir -p projects
mkdir -p assessments/{quizzes,practical-exams,rubrics}
mkdir -p resources/{reading-lists,tools,references,templates}
mkdir -p progress/{checkpoints,portfolio}
mkdir -p community/{office-hours,discussion-topics}
mkdir -p scripts

# Create 12 learning modules
for i in {101..112}; do
    case $i in
        101) module="ml-security-foundations" ;;
        102) module="zero-trust-architecture" ;;
        103) module="cryptography-for-ml" ;;
        104) module="network-security" ;;
        105) module="secrets-management" ;;
        106) module="adversarial-ml" ;;
        107) module="compliance-governance" ;;
        108) module="runtime-security" ;;
        109) module="policy-as-code" ;;
        110) module="supply-chain-security" ;;
        111) module="security-operations" ;;
        112) module="advanced-topics" ;;
    esac

    mkdir -p "lessons/mod-$i-$module"/{lectures,exercises,labs,resources}
    mkdir -p "lessons/mod-$i-$module/exercises/guided"
    mkdir -p "lessons/mod-$i-$module/labs/hands-on"
done

# Create 5 project directories
declare -A projects=(
    ["01"]="zero-trust-infra"
    ["02"]="compliance-framework"
    ["03"]="adversarial-defense"
    ["04"]="secure-cicd"
    ["05"]="security-soc"
)

for num in "${!projects[@]}"; do
    proj="${projects[$num]}"
    mkdir -p "projects/project-$num-$proj"/{src,tests,docs,kubernetes,security,scripts}
    mkdir -p "projects/project-$num-$proj/src/stubs"
    mkdir -p "projects/project-$num-$proj/tests/unit"
    mkdir -p "projects/project-$num-$proj/tests/integration"
    mkdir -p "projects/project-$num-$proj/docs/architecture"
done

echo "✓ Directory structure created"
echo "✓ 12 learning modules created"
echo "✓ 5 project directories created"
echo "Repository structure built successfully!"
