#!/bin/bash
set -e

# Script pour vérifier le score de mutation avec PIT
# Usage:
#   ./check-mutation-score.sh run            # Exécute PIT et affiche le score
#   ./check-mutation-score.sh compare <file> # Compare avec un rapport précédent

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonction pour exécuter les tests de mutation
run_mutation_tests() {
    echo "Exécution des tests de mutation PIT..."
    # Compiler le module core avant PIT pour garantir la présence des dépendances
    mvn test-compile -pl core
    # Exécuter PIT
    mvn org.pitest:pitest-maven:mutationCoverage -pl core -DwithHistory=false
}

# Fonction pour extraire le score de mutation depuis mutations.xml
extract_mutation_score() {
    local xml_file="$1"

    if [ ! -f "$xml_file" ]; then
        echo -e "${RED} Fichier de mutations introuvable: $xml_file${NC}"
        return 1
    fi

    # Compter le nombre total de mutations et les mutations détectées
    local total=$(grep -c "<mutation" "$xml_file" || echo "0")
    local killed=$(grep "detected='true'" "$xml_file" | wc -l || echo "0")

    if [ "$total" -eq 0 ]; then
        echo -e "${RED} Aucune mutation trouvée dans le rapport${NC}"
        return 1
    fi

    # Calculer le pourcentage (avec 2 décimales)
    local score=$(awk "BEGIN {printf \"%.2f\", ($killed/$total)*100}")

    echo "$score:$killed:$total"
}

# Fonction pour comparer deux scores
compare_scores() {
    local current_score="$1"
    local baseline_score="$2"
    local current_killed="$3"
    local current_total="$4"
    local baseline_killed="$5"
    local baseline_total="$6"

    echo ""
    echo " Résultats de la comparaison:"
    echo "----------------------------------------------"
    echo "  Score Master (baseline): ${baseline_score}% (${baseline_killed}/${baseline_total})"
    echo "  Score Actuel:            ${current_score}% (${current_killed}/${current_total})"
    echo "----------------------------------------------"

    # Comparer les scores (utiliser bc pour la comparaison de flottants)
    local diff=$(awk "BEGIN {printf \"%.2f\", $current_score - $baseline_score}")

    if (( $(echo "$current_score >= $baseline_score" | bc -l) )); then
        echo -e "${GREEN} SUCCÈS: Le score de mutation est maintenu ou amélioré${NC}"
        if (( $(echo "$diff > 0" | bc -l) )); then
            echo -e "${GREEN}   Amélioration: +${diff}%${NC}"
        fi
        return 0
    else
        echo -e "${RED} ÉCHEC: Le score de mutation a diminué${NC}"
        echo -e "${RED}   Régression: ${diff}%${NC}"
        echo ""
        echo -e "${YELLOW}  Veuillez ajouter des tests pour couvrir les mutations non détectées.${NC}"
        return 1
    fi
}

# Fonction principale
main() {
    local command="$1"
    local baseline_file="$2"

    case "$command" in
        run)
            run_mutation_tests
            local result=$(extract_mutation_score "core/target/pit-reports/mutations.xml")

            if [ $? -ne 0 ]; then
                exit 1
            fi

            IFS=':' read -r score killed total <<< "$result"
            echo ""
            echo "Score de mutation: ${score}% (${killed}/${total})"
            echo ""

            # Sauvegarder les résultats dans un fichier pour utilisation ultérieure
            echo "$result" > core/target/pit-reports/mutation-score.txt
            ;;

        compare)
            if [ -z "$baseline_file" ]; then
                echo -e "${RED} Erreur: Le fichier baseline est requis${NC}"
                echo "Usage: $0 compare <baseline-file>"
                exit 1
            fi

            if [ ! -f "$baseline_file" ]; then
                echo -e "${YELLOW} Aucun baseline trouvé. Premier build sur cette branche?${NC}"
                echo -e "${GREEN} Acceptation du score actuel comme nouveau baseline.${NC}"

                # Extraire et afficher le score actuel
                local current_result=$(extract_mutation_score "core/target/pit-reports/mutations.xml")
                IFS=':' read -r score killed total <<< "$current_result"
                echo "Score actuel: ${score}% (${killed}/${total})"
                exit 0
            fi

            # Extraire les scores
            local current_result=$(extract_mutation_score "core/target/pit-reports/mutations.xml")
            if [ $? -ne 0 ]; then
                exit 1
            fi

            IFS=':' read -r current_score current_killed current_total <<< "$current_result"

            # Lire le baseline depuis le fichier de mutations précédent
            local baseline_result=$(extract_mutation_score "$baseline_file")
            if [ $? -ne 0 ]; then
                echo -e "${YELLOW} Impossible de lire le baseline. Acceptation du score actuel.${NC}"
                exit 0
            fi

            IFS=':' read -r baseline_score baseline_killed baseline_total <<< "$baseline_result"

            # Comparer
            compare_scores "$current_score" "$baseline_score" \
                          "$current_killed" "$current_total" \
                          "$baseline_killed" "$baseline_total"
            exit $?
            ;;

        *)
            echo "Usage: $0 {run|compare <baseline-file>}"
            echo ""
            echo "Commandes:"
            echo "  run                    - Exécute PIT et affiche le score"
            echo "  compare <baseline>     - Compare avec un rapport baseline"
            exit 1
            ;;
    esac
}

main "$@"
