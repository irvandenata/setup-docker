# nuxt-landing-page — static build served by nginx
# Build context: repo root (setup/docker-compose.yml uses context: ..)

FROM node:22-alpine AS builder
RUN corepack enable && corepack prepare pnpm@latest --activate
WORKDIR /app

# Copy source first — postinstall runs nuxt prepare + build:icons which need source
COPY nuxt-landing-page/ .

RUN pnpm install --no-frozen-lockfile --ignore-scripts
RUN pnpm nuxt prepare
RUN pnpm run build:icons
RUN pnpm generate

# ── runner ────────────────────────────────────────────────────────────────
FROM nginx:stable-alpine AS runner

COPY --from=builder /app/.output/public /usr/share/nginx/html
COPY setup/nginx.landing.conf.template /etc/nginx/nginx.conf.template

# envsubst replaces ${VAR} placeholders at startup; nginx vars ($host, etc.)
# are preserved by listing only the app-level vars to substitute.
EXPOSE 80
CMD ["/bin/sh", "-c", \
  "envsubst '${APP_RESERVASI} ${APP_KERJASAMA} ${APP_PERSURATAN} ${APP_MONITORING} ${APP_WILAYAH} ${APP_AMS} ${APP_SURVEY} ${APP_PUBLIK} ${APP_HELPDESK}' \
    < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf \
  && nginx -g 'daemon off;'"]
