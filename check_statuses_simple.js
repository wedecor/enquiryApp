#!/usr/bin/env node

// Simple script to check statuses using Firebase REST API
// This doesn't require Firebase Admin SDK

const https = require('https');

const PROJECT_ID = 'wedecorenquries';
const COLLECTION_PATH = 'dropdowns/statuses/items';

// Firebase REST API URL
const url = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/${COLLECTION_PATH}`;

console.log('🔍 Checking statuses in Firebase database...');
console.log(`📡 Fetching from: ${url}`);

// Make request to Firebase REST API
https.get(url, (res) => {
  let data = '';
  
  res.on('data', (chunk) => {
    data += chunk;
  });
  
  res.on('end', () => {
    try {
      const response = JSON.parse(data);
      
      if (response.documents) {
        console.log(`\n📊 Found ${response.documents.length} status documents:`);
        
        const statuses = response.documents.map(doc => {
          const fields = doc.fields;
          return {
            id: doc.name.split('/').pop(),
            value: fields.value?.stringValue || 'N/A',
            label: fields.label?.stringValue || 'N/A',
            order: fields.order?.integerValue || 0,
            active: fields.active?.booleanValue !== false,
            color: fields.color?.stringValue || 'N/A'
          };
        });
        
        // Sort by order
        statuses.sort((a, b) => a.order - b.order);
        
        console.log('\n📋 Status List:');
        statuses.forEach(status => {
          const statusText = `${status.label} (${status.value})`;
          const orderText = `Order: ${status.order}`;
          const activeText = status.active ? '✅ Active' : '❌ Inactive';
          const colorText = `Color: ${status.color}`;
          console.log(`  • ${statusText} | ${orderText} | ${activeText} | ${colorText}`);
        });
        
        console.log('\n🎯 Expected vs Actual:');
        const expectedStatuses = [
          'new', 'in_talks', 'quotation_sent', 'confirmed', 'completed', 'cancelled', 'not_interested'
        ];
        
        const actualValues = statuses.map(s => s.value);
        
        expectedStatuses.forEach(expected => {
          const found = actualValues.includes(expected);
          console.log(`  ${found ? '✅' : '❌'} ${expected}: ${found ? 'Found' : 'Missing'}`);
        });
        
        const extraStatuses = actualValues.filter(val => !expectedStatuses.includes(val));
        if (extraStatuses.length > 0) {
          console.log('\n⚠️  Extra statuses found:');
          extraStatuses.forEach(extra => {
            console.log(`  • ${extra}`);
          });
        }
        
      } else {
        console.log('❌ No documents found or unexpected response structure');
        console.log('Response:', JSON.stringify(response, null, 2));
      }
      
    } catch (error) {
      console.error('❌ Error parsing response:', error.message);
      console.log('Raw response:', data);
    }
  });
  
}).on('error', (error) => {
  console.error('❌ Error making request:', error.message);
});
