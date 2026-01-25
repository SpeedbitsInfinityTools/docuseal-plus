#!/bin/bash
set -e

echo "🚀 Starting DocuSeal Development Environment..."

# Wait for PostgreSQL to be ready
echo "⏳ Waiting for PostgreSQL..."
until pg_isready -h postgres -U postgres -q; do
  sleep 1
done
echo "✅ PostgreSQL is ready"

# Wait for Redis to be ready
echo "⏳ Waiting for Redis..."
until redis-cli -h redis ping > /dev/null 2>&1; do
  sleep 1
done
echo "✅ Redis is ready"

# Setup database if needed
echo "📦 Setting up database..."
bundle exec rails db:prepare

# Start all services in background
echo "🌐 Starting Rails server..."
bundle exec rails s -b 0.0.0.0 -p 3000 &

echo "📦 Starting Webpack dev server..."
bin/shakapacker-dev-server &

echo "⚙️  Starting Sidekiq..."
bundle exec sidekiq &

echo ""
echo "✨ DocuSeal is starting up!"
echo "   Web App: http://localhost:3000"
echo ""
echo "   (First request may take ~30 seconds while assets compile)"
echo ""

# Keep the script running and forward signals
wait
