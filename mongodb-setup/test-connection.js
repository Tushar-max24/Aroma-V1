// Test script to verify MongoDB server is running
const http = require('http');

const options = {
  hostname: 'localhost',
  port: 3000,
  path: '/api/health',
  method: 'GET',
  headers: {
    'Content-Type': 'application/json',
  },
};

const req = http.request(options, (res) => {
  console.log(`Status Code: ${res.statusCode}`);
  console.log(`Response Headers: ${JSON.stringify(res.headers)}`);
  
  let data = '';
  
  res.on('data', (chunk) => {
    data += chunk;
  });
  
  res.on('end', () => {
    console.log('Response Body:', data);
    
    if (res.statusCode === 200) {
      console.log('✅ MongoDB server is running and accessible!');
      
      // Test adding an ingredient
      testAddIngredient();
    } else {
      console.log('❌ MongoDB server is not responding correctly');
    }
  });
});

req.on('error', (error) => {
  console.error('❌ Error connecting to MongoDB server:', error.message);
});

req.end();

// Test adding an ingredient
function testAddIngredient() {
  const testData = JSON.stringify({
    name: 'Test Tomato',
    image_url: 'http://example.com/tomato.jpg',
    common_units: ['pcs', 'g', 'kg']
  });
  
  const addOptions = {
    hostname: 'localhost',
    port: 3000,
    path: '/api/ingredients',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(testData),
    },
  };
  
  const addReq = http.request(addOptions, (res) => {
    console.log(`\nAdd Ingredient Status Code: ${res.statusCode}`);
    
    let data = '';
    res.on('data', (chunk) => { data += chunk; });
    res.on('end', () => {
      console.log('Add Ingredient Response:', data);
      
      if (res.statusCode === 201) {
        console.log('✅ Successfully added test ingredient!');
      } else {
        console.log('⚠️ Ingredient might already exist or there was an error');
      }
    });
  });
  
  addReq.on('error', (error) => {
    console.error('❌ Error adding ingredient:', error.message);
  });
  
  addReq.write(testData);
  addReq.end();
}
