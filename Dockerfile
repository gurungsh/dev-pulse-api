# Red Hat's UBI Node.js image runs as a non-root user and works with the random
# UIDs OpenShift assigns. It also ships OpenSSL, which Prisma's engines need.
FROM registry.access.redhat.com/ubi9/nodejs-20 AS build
WORKDIR /opt/app-root/src

# The schema has to be in place before `npm ci`, because postinstall runs `prisma generate`.
COPY --chown=1001:0 package.json package-lock.json ./
COPY --chown=1001:0 prisma ./prisma
RUN npm ci

COPY --chown=1001:0 tsconfig.json ./
COPY --chown=1001:0 src ./src
RUN npm run build && npm prune --omit=dev

FROM registry.access.redhat.com/ubi9/nodejs-20-minimal
LABEL org.opencontainers.image.source=https://github.com/gurungsh/dev-pulse-api
WORKDIR /opt/app-root/src
ENV NODE_ENV=production

COPY --from=build /opt/app-root/src/package.json ./
COPY --from=build /opt/app-root/src/node_modules ./node_modules
COPY --from=build /opt/app-root/src/prisma ./prisma
COPY --from=build /opt/app-root/src/dist ./dist

# The base image already runs as 1001; stating it keeps scanners from flagging a root container.
# OpenShift replaces it with a random UID at runtime.
USER 1001

EXPOSE 8080
# `npm start` applies pending migrations, then starts the server.
CMD ["npm", "start"]
