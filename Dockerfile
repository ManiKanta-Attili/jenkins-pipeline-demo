# Base image
FROM python:3.12-slim

# Set working directory
WORKDIR /app

# Copy files
COPY app.py /app/

# Command to run the app
CMD ["python3", "app.py"]
