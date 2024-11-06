const fastify = require('fastify');

const app = fastify({
    logger: true
});

app.get('/', async function (req, reply) {
    return { hello: 'world', query: req.query };
});

app.listen({ host: '0.0.0.0', port: 3000 });
