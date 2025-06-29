import React from 'react';
import { Box, Typography, Card, CardContent } from '@mui/material';
import { useParams } from 'react-router-dom';

const DeviceDetail = () => {
  const { deviceId } = useParams();

  return (
    <Box>
      <Typography variant="h4" fontWeight="bold" gutterBottom>
        Device Details
      </Typography>
      <Card>
        <CardContent>
          <Typography variant="body1">
            Device ID: {deviceId}
          </Typography>
          <Typography variant="body2" color="text.secondary" sx={{ mt: 2 }}>
            Device details page is under construction.
          </Typography>
        </CardContent>
      </Card>
    </Box>
  );
};

export default DeviceDetail; 