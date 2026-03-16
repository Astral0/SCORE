#!/bin/bash

# Script de demarrage pour SCORE - Enterprise Document Repository Analysis
# Lance le serveur Django dans une session screen

set -e

# Configuration
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$SCRIPT_DIR"
LOG_DIR="$PROJECT_DIR/logs"
SCREEN_SESSION="score"

# Configuration des serveurs
DJANGO_PORT=8000
CONDA_ENV="score"

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}  DEMARRAGE SERVEUR - SCORE${NC}"
echo -e "${BLUE}  Enterprise Document Repository Analysis${NC}"
echo -e "${BLUE}===============================================${NC}"
echo ""

# Creer le repertoire de logs s'il n'existe pas
mkdir -p "$LOG_DIR"

# Verification des prerequis
echo -e "${YELLOW}[1/3] Verification des prerequis...${NC}"

# Verifier si screen est installe
if ! command -v screen &> /dev/null; then
    echo -e "${RED}ERREUR: screen n'est pas installe${NC}"
    echo "Installez-le avec: sudo apt install screen"
    exit 1
fi

# Verifier manage.py
if [ ! -f "$PROJECT_DIR/manage.py" ]; then
    echo -e "${RED}ERREUR: manage.py non trouve dans $PROJECT_DIR${NC}"
    exit 1
fi

echo -e "${GREEN}Prerequis OK${NC}"

# Demarrage de Redis
echo -e "${YELLOW}[1.5/3] Demarrage de Redis...${NC}"
if redis-cli ping &> /dev/null; then
    echo -e "${GREEN}Redis deja en cours d'execution${NC}"
else
    redis-server --daemonize yes 2>/dev/null
    sleep 1
    if redis-cli ping &> /dev/null; then
        echo -e "${GREEN}Redis demarre sur le port 6379${NC}"
    else
        echo -e "${RED}ERREUR: Impossible de demarrer Redis${NC}"
        exit 1
    fi
fi

# Recherche de l'environnement conda
echo -e "${YELLOW}[2/3] Recherche de conda...${NC}"

CONDA_BASE=""
for conda_path in "$HOME/anaconda3" "$HOME/miniconda3" "/opt/anaconda3" "/opt/miniconda3" "/usr/local/anaconda3" "/usr/local/miniconda3"; do
    if [ -f "$conda_path/etc/profile.d/conda.sh" ]; then
        CONDA_BASE="$conda_path"
        break
    fi
done

if [ -z "$CONDA_BASE" ] && command -v conda &> /dev/null; then
    CONDA_BASE="$(conda info --base 2>/dev/null)"
fi

if [ -z "$CONDA_BASE" ] || [ ! -f "$CONDA_BASE/etc/profile.d/conda.sh" ]; then
    echo -e "${RED}ERREUR: Conda non trouve${NC}"
    echo "Installez Anaconda ou Miniconda"
    exit 1
fi

echo -e "${GREEN}Conda trouve: $CONDA_BASE${NC}"

# Verifier si une session screen existe deja
echo -e "${YELLOW}[3/3] Demarrage du serveur Django...${NC}"

if screen -ls | grep -q "$SCREEN_SESSION"; then
    echo -e "${YELLOW}La session screen '$SCREEN_SESSION' existe deja.${NC}"
    echo -e "Pour vous y connecter: ${GREEN}screen -r $SCREEN_SESSION${NC}"
    echo ""
    read -p "Voulez-vous la fermer et en creer une nouvelle ? (o/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Oo]$ ]]; then
        screen -S "$SCREEN_SESSION" -X quit
        sleep 1
        echo -e "${GREEN}Session precedente fermee${NC}"
        fuser -k "$DJANGO_PORT/tcp" 2>/dev/null || true
        sleep 1
    else
        echo -e "${YELLOW}Conservation de la session existante${NC}"
        echo -e "Connectez-vous avec: ${GREEN}screen -r $SCREEN_SESSION${NC}"
        exit 0
    fi
fi

echo -e "${GREEN}Creation de la session screen '$SCREEN_SESSION'...${NC}"

# Creer le script wrapper
WRAPPER="/tmp/score_django_$$.sh"
cat > "$WRAPPER" << EOF
#!/bin/bash
source "$CONDA_BASE/etc/profile.d/conda.sh"
conda activate $CONDA_ENV
cd "$PROJECT_DIR"

echo "=== Demarrage de SCORE ==="
echo "Repertoire: \$(pwd)"
echo "Environnement conda: \$CONDA_DEFAULT_ENV"
echo "Python: \$(python --version)"
echo "Pour arreter: Ctrl+C"
echo ""

trap '
    echo ""
    echo "=== SCORE interrompu ==="
    echo ""
' INT

python manage.py runserver 0.0.0.0:$DJANGO_PORT 2>&1 | tee "$LOG_DIR/django.log"

echo ""
echo "=== SCORE termine ==="
echo ""
exec bash
EOF
chmod +x "$WRAPPER"

screen -dmS "$SCREEN_SESSION" bash -c "$WRAPPER; rm -f $WRAPPER"
sleep 1

# Creer le worker Celery dans un deuxieme onglet screen
CELERY_WRAPPER="/tmp/score_celery_$$.sh"
cat > "$CELERY_WRAPPER" << EOF
#!/bin/bash
source "$CONDA_BASE/etc/profile.d/conda.sh"
conda activate $CONDA_ENV
cd "$PROJECT_DIR"

echo "=== Demarrage du worker Celery ==="
echo "Pour arreter: Ctrl+C"
echo ""

trap '
    echo ""
    echo "=== Celery interrompu ==="
    echo ""
' INT

celery -A score worker -l info --pool threads 2>&1 | tee "$LOG_DIR/celery.log"

echo ""
echo "=== Celery termine ==="
echo ""
exec bash
EOF
chmod +x "$CELERY_WRAPPER"

screen -S "$SCREEN_SESSION" -X screen -t "celery" bash -c "$CELERY_WRAPPER; rm -f $CELERY_WRAPPER"
sleep 2

echo ""
echo -e "${GREEN}===============================================${NC}"
echo -e "${GREEN}  SERVEUR DEMARRE${NC}"
echo -e "${GREEN}===============================================${NC}"
echo ""
echo -e "Le serveur est lance dans la session screen '${BLUE}$SCREEN_SESSION${NC}'"
echo ""
echo -e "${YELLOW}URLs:${NC}"
echo -e "  - Application:  ${GREEN}http://localhost:$DJANGO_PORT${NC}"
echo -e "  - Admin Django:  ${GREEN}http://localhost:$DJANGO_PORT/admin${NC}"
echo ""
echo -e "${YELLOW}Compte admin:${NC}"
echo -e "  - Username: ${GREEN}admin${NC}"
echo -e "  - Password: ${GREEN}admin123${NC}"
echo ""
echo -e "${YELLOW}Commandes utiles:${NC}"
echo -e "  - Se connecter a la session:  ${GREEN}screen -r $SCREEN_SESSION${NC}"
echo -e "  - Detacher la session:        ${GREEN}Ctrl+A puis d${NC}"
echo -e "  - Fermer la session:          ${GREEN}screen -S $SCREEN_SESSION -X quit${NC}"
echo ""
echo -e "${YELLOW}Session screen (2 onglets):${NC}"
echo -e "  - Onglet 0: ${GREEN}Django${NC} (serveur web)"
echo -e "  - Onglet 1: ${GREEN}Celery${NC} (worker tâches async)"
echo -e "  - Naviguer: ${GREEN}Ctrl+A puis n${NC} (suivant) ou ${GREEN}p${NC} (precedent)"
echo ""
echo -e "${YELLOW}Logs:${NC}"
echo -e "  - Django: ${GREEN}$LOG_DIR/django.log${NC}"
echo -e "  - Celery: ${GREEN}$LOG_DIR/celery.log${NC}"
echo ""
