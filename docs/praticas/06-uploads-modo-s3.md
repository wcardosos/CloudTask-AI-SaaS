# Prática 06 — Uploads em modo S3 (Amazon)

> **Objetivo:** mandar o mesmo `/uploads` para um bucket **S3 de verdade** e
> baixar via **URL pré-assinada**.
>
> **Tempo:** 25 min.
>
> **Pré-req:**
> 1. Sessão do Learner Lab ativa (credenciais coladas em `~/.aws/credentials`).
> 2. AWS CLI funcionando: `aws sts get-caller-identity` retorna seu ARN.
> 3. Prática [05](05-uploads-modo-local.md) feita.
>
> **Aula:** 5 (Semana 3).

---

## 1. Confirmar credenciais

No terminal do devcontainer:

```bash
aws sts get-caller-identity
```

Saída deve ter `"Account"`, `"Arn"`. Se der `Unable to locate credentials`:

- Verifique se colou as credenciais em `~/.aws/credentials` no **host**
  (Windows: `C:\Users\seu-nome\.aws\credentials`).
- Veja [`00-setup-inicial-e-aws-academy.md`](00-setup-inicial-e-aws-academy.md), Parte 3.

> ⚠️ **Learner Lab expira:** as credenciais duram ~4 horas. Quando expirar,
> abra a sessão de novo no AWS Academy e cole as novas em
> `~/.aws/credentials`. O mount do devcontainer enxerga na hora — sem rebuild.

---

## 2. Criar bucket S3

Nomes de bucket são **globais** na AWS — escolha algo único:

```bash
export BUCKET=cloudtask-uploads-$(whoami)-$(date +%s)
echo $BUCKET

aws s3 mb s3://$BUCKET --region us-east-1
```

> 💡 **POR QUÊ `us-east-1`?** Região default do Learner Lab. Se mudar, edite
> também `AWS_REGION` no `.env`.

Confirmar:

```bash
aws s3 ls
# 2026-XX-XX HH:MM:SS cloudtask-uploads-seu-nome-1234567890
```

---

## 3. Configurar `.env` pra modo S3

Edite o `.env` na raiz do projeto:

```env
STORAGE_MODE=s3
AWS_REGION=us-east-1
S3_BUCKET_NAME=cloudtask-uploads-seu-nome-1234567890
S3_PRESIGNED_URL_EXPIRES=3600
```

Recriar o container pra carregar o novo `.env`:

```bash
docker compose down
docker compose up -d
```

> 💡 **`restart` NÃO basta** porque `.env` é lido na criação do container, não a
> cada start. `down`+`up` cria de novo.

---

## 4. Upload em S3

```bash
echo "olá nuvem" > nuvem.txt
curl -i -X POST -F "file=@nuvem.txt" http://localhost:8000/uploads
```

Resposta agora deve trazer `"storage_mode":"s3"` e uma URL **pré-assinada** longa:

```
HTTP/1.1 201 Created
{
  "filename": "9a4b...nuvem.txt",
  "url": "https://cloudtask-uploads-...s3.amazonaws.com/9a4b...nuvem.txt?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=...&X-Amz-Date=...&X-Amz-Expires=3600&X-Amz-SignedHeaders=host&X-Amz-Signature=...",
  "size_bytes": 11,
  "storage_mode": "s3"
}
```

> 💡 **URL pré-assinada:** um link **temporário** (expira em
> `S3_PRESIGNED_URL_EXPIRES` segundos = 1h) que dá acesso ao objeto SEM
> precisar de credenciais AWS no cliente. O backend assinou para você.

---

## 5. Conferir no bucket

```bash
aws s3 ls s3://$BUCKET/
# 2026-XX-XX HH:MM:SS  11  9a4b...nuvem.txt
```

Ou no Console AWS:

1. Abra `https://s3.console.aws.amazon.com/`.
2. Clique no seu bucket.
3. Veja o objeto.

---

## 6. Baixar via GET (redirect 307)

```bash
curl -iL http://localhost:8000/uploads/9a4b...nuvem.txt
```

Você verá:

```
HTTP/1.1 307 Temporary Redirect
Location: https://cloudtask-uploads-...s3.amazonaws.com/9a4b...?X-Amz-...
...

HTTP/1.1 200 OK
[conteúdo do arquivo]
```

> 💡 **POR QUÊ redirect, não streaming?** No modo S3 a API **não baixa o
> arquivo do S3 para devolver pro cliente** (custo de banda, latência). Ela
> apenas devolve um redirect 307 com a URL pré-assinada — o navegador/cliente
> baixa **direto do S3**, economizando tudo.

A flag `-L` no curl segue o redirect automaticamente.

---

## 7. Tornar público (NÃO recomendado) — só para entender ACL

> ⚠️ **NÃO faça isso em produção.** Buckets públicos são uma das principais
> causas de vazamento de dados em LGPD/GDPR. Aqui é só pra você ver na prática
> que **bucket privado + URL pré-assinada** é o padrão correto.

(Pulamos esse passo — fica como leitura conceitual em
[`../conceitos/s3-efs-datalake.md`](../conceitos/s3-efs-datalake.md).)

---

## 8. **LIMPEZA OBRIGATÓRIA** (custos!)

> ⚠️ **NÃO PULE.** Mesmo um bucket vazio gera custo de listagem se tiver muito
> tráfego. No Learner Lab há limite de crédito — não desperdice.

```bash
# 1. apagar objetos do bucket
aws s3 rm s3://$BUCKET --recursive

# 2. apagar o bucket
aws s3 rb s3://$BUCKET

# 3. confirmar
aws s3 ls
# (não deve listar o bucket apagado)
```

---

## 9. Voltar para modo local

Edite `.env`:

```env
STORAGE_MODE=local
```

```bash
docker compose down && docker compose up -d
```

---

## Erros comuns

| Erro | Causa | Fix |
| --- | --- | --- |
| `Unable to locate credentials` | sem `~/.aws/credentials` | colar credenciais (Parte 3 do setup-inicial) |
| `The AWS Access Key Id you provided does not exist in our records` | credenciais expiraram | nova sessão no Learner Lab |
| `BucketAlreadyExists` | nome de bucket já em uso no mundo | adicione sufixo único (timestamp + seu nome) |
| `Access Denied` ao criar | sua role não tem permissão (raro no Learner Lab) | confirme com `aws s3 ls` que tem leitura básica |
| `storage_mode` ainda diz `"local"` após mudar `.env` | container não foi recriado | `docker compose down && docker compose up -d` |
| `botocore.exceptions.NoRegionError` | `AWS_REGION` faltando no `.env` | adicione `AWS_REGION=us-east-1` |

---

## Próximo passo

→ [`07-rodar-testes.md`](07-rodar-testes.md): rodar `pytest` no devcontainer
e em container isolado.
