# Build stage
FROM golang:1.23-alpine AS builder

# Instalar dependências de build
RUN apk add --no-cache git ca-certificates tzdata

# Definir diretório de trabalho
WORKDIR /app

# Copiar go.mod e go.sum
COPY go.mod go.sum ./

# Baixar dependências
RUN go mod download

# Copiar código fonte
COPY . .

# Compilar aplicação
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -a -installsuffix cgo -o main ./cmd/api

# Production stage
FROM alpine:latest

# Instalar dependências necessárias
RUN apk --no-cache add ca-certificates tzdata

# Criar usuário não-root
RUN adduser -D -s /bin/sh orthotrack

# Definir diretório de trabalho
WORKDIR /home/orthotrack

# Copiar binário compilado
COPY --from=builder /app/main .

# Definir propriedade dos arquivos
RUN chown orthotrack:orthotrack main

# Mudar para usuário não-root
USER orthotrack

# Expor porta
EXPOSE 8080

# Comando de execução
CMD ["./main"]