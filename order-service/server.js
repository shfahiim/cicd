const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const axios = require('axios');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3002;
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/microservices';
const USER_SERVICE_URL = process.env.USER_SERVICE_URL || 'http://localhost:3001';
const PRODUCT_SERVICE_URL = process.env.PRODUCT_SERVICE_URL || 'http://localhost:3003';

// Middleware
app.use(cors());
app.use(express.json());

// Order Schema
const orderSchema = new mongoose.Schema({
  userId: {
    type: String,
    required: true
  },
  productId: {
    type: String,
    required: true
  },
  quantity: {
    type: Number,
    required: true,
    min: 1
  },
  totalPrice: {
    type: Number,
    required: true
  },
  status: {
    type: String,
    enum: ['pending', 'confirmed', 'shipped', 'delivered', 'cancelled'],
    default: 'pending'
  },
  userDetails: {
    type: Object,
    default: {}
  },
  productDetails: {
    type: Object,
    default: {}
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

const Order = mongoose.model('Order', orderSchema);

// Connect to MongoDB
mongoose.connect(MONGODB_URI)
  .then(() => console.log('✅ Order Service: Connected to MongoDB'))
  .catch(err => console.error('❌ Order Service: MongoDB connection error:', err));

// Helper function to validate user
async function validateUser(userId) {
  try {
    const response = await axios.get(`${USER_SERVICE_URL}/users/${userId}`);
    return response.data;
  } catch (error) {
    if (error.response && error.response.status === 404) {
      throw new Error('User not found');
    }
    throw new Error('Failed to validate user: ' + error.message);
  }
}

// Helper function to validate product
async function validateProduct(productId, quantity) {
  try {
    const response = await axios.get(`${PRODUCT_SERVICE_URL}/products/${productId}`);
    const product = response.data.data;
    
    if (product.stock < quantity) {
      throw new Error('Insufficient stock');
    }
    
    return product;
  } catch (error) {
    if (error.response && error.response.status === 404) {
      throw new Error('Product not found');
    }
    if (error.message === 'Insufficient stock') {
      throw error;
    }
    throw new Error('Failed to validate product: ' + error.message);
  }
}

// Routes

// Health check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    service: 'order-service',
    timestamp: new Date().toISOString(),
    dependencies: {
      userService: USER_SERVICE_URL,
      productService: PRODUCT_SERVICE_URL
    }
  });
});

// Get all orders
app.get('/orders', async (req, res) => {
  try {
    const orders = await Order.find().sort({ createdAt: -1 });
    res.json({
      success: true,
      count: orders.length,
      data: orders
    });
  } catch (error) {
    res.status(500).json({ 
      success: false, 
      error: error.message 
    });
  }
});

// Get order by ID
app.get('/orders/:id', async (req, res) => {
  try {
    const order = await Order.findById(req.params.id);
    if (!order) {
      return res.status(404).json({ 
        success: false, 
        error: 'Order not found' 
      });
    }
    res.json({
      success: true,
      data: order
    });
  } catch (error) {
    res.status(500).json({ 
      success: false, 
      error: error.message 
    });
  }
});

// Create a new order (with inter-service communication)
app.post('/orders', async (req, res) => {
  try {
    const { userId, productId, quantity } = req.body;
    
    // Validate input
    if (!userId || !productId || !quantity) {
      return res.status(400).json({ 
        success: false, 
        error: 'UserId, productId, and quantity are required' 
      });
    }

    if (quantity < 1) {
      return res.status(400).json({ 
        success: false, 
        error: 'Quantity must be at least 1' 
      });
    }

    // Validate user exists (inter-service communication)
    let userResponse;
    try {
      userResponse = await validateUser(userId);
    } catch (error) {
      return res.status(400).json({ 
        success: false, 
        error: error.message 
      });
    }

    // Validate product exists and has sufficient stock (inter-service communication)
    let product;
    try {
      product = await validateProduct(productId, quantity);
    } catch (error) {
      return res.status(400).json({ 
        success: false, 
        error: error.message 
      });
    }

    // Calculate total price
    const totalPrice = product.price * quantity;

    // Create order
    const order = new Order({ 
      userId, 
      productId, 
      quantity,
      totalPrice,
      userDetails: userResponse.data,
      productDetails: {
        name: product.name,
        price: product.price
      }
    });
    await order.save();

    // Update product stock (inter-service communication)
    try {
      await axios.patch(`${PRODUCT_SERVICE_URL}/products/${productId}/stock`, {
        quantity
      });
    } catch (error) {
      // Rollback: delete the order if stock update fails
      await Order.findByIdAndDelete(order._id);
      return res.status(500).json({ 
        success: false, 
        error: 'Failed to update product stock: ' + error.message 
      });
    }
    
    res.status(201).json({
      success: true,
      message: 'Order created successfully',
      data: order
    });
  } catch (error) {
    res.status(500).json({ 
      success: false, 
      error: error.message 
    });
  }
});

// Update order status
app.patch('/orders/:id/status', async (req, res) => {
  try {
    const { status } = req.body;
    const validStatuses = ['pending', 'confirmed', 'shipped', 'delivered', 'cancelled'];
    
    if (!validStatuses.includes(status)) {
      return res.status(400).json({ 
        success: false, 
        error: `Invalid status. Must be one of: ${validStatuses.join(', ')}` 
      });
    }

    const order = await Order.findByIdAndUpdate(
      req.params.id,
      { status },
      { new: true }
    );
    
    if (!order) {
      return res.status(404).json({ 
        success: false, 
        error: 'Order not found' 
      });
    }
    
    res.json({
      success: true,
      message: 'Order status updated successfully',
      data: order
    });
  } catch (error) {
    res.status(500).json({ 
      success: false, 
      error: error.message 
    });
  }
});

// Delete order
app.delete('/orders/:id', async (req, res) => {
  try {
    const order = await Order.findByIdAndDelete(req.params.id);
    if (!order) {
      return res.status(404).json({ 
        success: false, 
        error: 'Order not found' 
      });
    }
    res.json({
      success: true,
      message: 'Order deleted successfully'
    });
  } catch (error) {
    res.status(500).json({ 
      success: false, 
      error: error.message 
    });
  }
});

// Get orders by user ID
app.get('/orders/user/:userId', async (req, res) => {
  try {
    const orders = await Order.find({ userId: req.params.userId }).sort({ createdAt: -1 });
    res.json({
      success: true,
      count: orders.length,
      data: orders
    });
  } catch (error) {
    res.status(500).json({ 
      success: false, 
      error: error.message 
    });
  }
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Order Service running on port ${PORT}`);
  console.log(`📡 Connected to User Service at: ${USER_SERVICE_URL}`);
  console.log(`📡 Connected to Product Service at: ${PRODUCT_SERVICE_URL}`);
});

module.exports = app;
