# =============================================================================
# .zshrc do devcontainer — CloudTask AI SaaS
# -----------------------------------------------------------------------------
# Copiado para ~/.zshrc pelo post-create.sh. Configura o oh-my-zsh com um tema
# de DUAS LINHAS e informativo, além de plugins úteis para o projeto.
#
# POR QUÊ o tema "fino-time": mostra, em duas linhas, usuário@host, diretório
# atual, branch do git e a hora — exatamente o "onde estou?" que ajuda o aluno.
# Usa só caracteres comuns (├ ╰ ─ ‹ ›), funcionando na maioria das fontes de
# terminal SEM precisar de Nerd Font. Se algum glifo (a setinha ➜) não aparecer
# bonito na sua fonte, o prompt continua 100% funcional.
# =============================================================================

export ZSH="$HOME/.oh-my-zsh"

# Tema de duas linhas com bastante informação (ver comentário acima).
ZSH_THEME="fino-time"

# Plugins do oh-my-zsh: adicionam autocompletar e atalhos por ferramenta.
#   git           -> status/branch no prompt, aliases (gst, gco, gp...)
#   aws           -> completar aws-cli; asp/agp p/ trocar/ver profile
#   docker        -> completar docker
#   docker-compose-> completar docker compose
#   kubectl       -> alias `k` + completar kubectl
#   helm          -> completar helm
#   python / pip  -> completar python e pip
#   postgres      -> aliases para psql/pg_dump etc.
#   vscode        -> helper `code` dentro do container
#   colored-man-pages -> man pages coloridas
#   zsh-autosuggestions     -> sugere comandos do histórico enquanto digita
#   zsh-syntax-highlighting -> colore o comando (verde=ok, vermelho=erro)  [POR ÚLTIMO]
plugins=(
  git
  aws
  docker
  docker-compose
  kubectl
  helm
  python
  pip
  postgres
  vscode
  colored-man-pages
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source "$ZSH/oh-my-zsh.sh"

# Binários Python instalados com `pip install --user` (uvicorn, pytest, ruff...).
export PATH="$HOME/.local/bin:$PATH"

# ----- Atalhos do projeto ----------------------------------------------------
alias dc='docker compose'
alias dcup='docker compose up'
alias dcdown='docker compose down'
alias dclogs='docker compose logs -f api'
alias k='kubectl'
alias serve='uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload'
alias health='curl -s http://localhost:8000/health; echo'
alias ready='curl -s http://localhost:8000/health/ready; echo'
alias tasks='curl -s http://localhost:8000/tasks; echo'
alias t='pytest -q'
alias tv='pytest -v'
alias cov='pytest --cov=app'
alias psqldb='psql "$DATABASE_URL"'

# Mostra o contexto atual do Kubernetes (qual cluster) — útil nas Aulas 6-9.
alias kctx='kubectl config current-context 2>/dev/null || echo "(sem cluster k8s configurado)"'
# Mostra a identidade/conta AWS ativa — útil nas Aulas 5,7-11.
alias whoaws='aws sts get-caller-identity 2>/dev/null || echo "(sem credencial AWS ativa)"'

# Mensagem de boas-vindas (ajuda o aluno a se localizar).
echo "CloudTask AI SaaS — devcontainer. App em http://localhost:8000/docs | testes: tv | logs: dclogs"
