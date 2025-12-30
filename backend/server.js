const jsonServer = require('json-server');
const server = jsonServer.create();
const router = jsonServer.router('db.json');
const middlewares = jsonServer.defaults();
const cors = require('cors');

const PORT = process.env.PORT || 3000;

// Enable CORS for all routes
server.use(cors());

// Add custom routes before JSON Server router
server.use(jsonServer.rewriter({
    '/api/': '/',
}));

// Middleware
server.use(middlewares);
server.use(jsonServer.bodyParser);

// Add delay to simulate real API
server.use((req, res, next) => {
    setTimeout(next, 100);
});

// Use default router
server.use(router);

// Start server
server.listen(PORT, () => {
    console.log(`JSON Server is running on port ${PORT}`);
});
