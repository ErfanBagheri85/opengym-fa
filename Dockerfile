# Multi-stage: frontend + API + exercise media, served together by nginx
# on ONE origin (required for passkeys).

FROM --platform=$BUILDPLATFORM node:22-alpine AS build
WORKDIR /app
COPY frontend/package.json frontend/package-lock.json* ./
RUN npm ci 2>/dev/null || npm install
COPY frontend/ ./
RUN npm run build

FROM node:22-alpine AS api-deps
WORKDIR /app/api
COPY api/package.json api/package-lock.json* ./
RUN npm ci --omit=dev 2>/dev/null || npm install --omit=dev
COPY api/ ./

FROM alpine/git AS media
RUN git clone --depth 1 https://github.com/hasaneyldrm/exercises-dataset /tmp/ds \
    && mkdir -p /out/img /out/gif \
    && cp /tmp/ds/images/*.jpg /out/img/ \
    && cp /tmp/ds/videos/*.gif /out/gif/

FROM node:22-alpine
RUN apk add --no-cache nginx
COPY nginx.conf /etc/nginx/http.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html
COPY --from=media /out/img /usr/share/nginx/html/img
COPY --from=media /out/gif /usr/share/nginx/html/gif
COPY --from=api-deps /app/api /app/api
COPY start.sh /start.sh
RUN chmod +x /start.sh
EXPOSE 80
CMD ["/start.sh"]
