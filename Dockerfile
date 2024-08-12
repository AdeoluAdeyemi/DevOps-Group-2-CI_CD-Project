# Load base image
# ------------------------------------- Single stage build -----------------------------------------------------
  FROM python:3.11-alpine3.18 AS single-stage
  LABEL maintainer="Adeolu Adeyemi <ade@adeoluadeyemi.com>"
  
  # Install curl and unzip
  RUN apk add --no-cache curl unzip
  
  # Set working directory 
  WORKDIR /usr/src/app
  
  # Copy dependencies from host to WD
  COPY requirements.txt ./
  
  # Install dependencies
  RUN pip install --upgrade pip
  RUN pip install --no-cache-dir -r requirements.txt
  
  # Copy all application files from host to WD
  COPY . .
  
  # Remove existing GOV.UK Frontend assets
  RUN rm -rf static/fonts \
      rm -rf static/images \
      rm -rf static/govuk-frontend* \
      rm -rf static/VERSION.txt
  
  # Get new release distribution assets and move to static directory
  RUN curl -L https://github.com/alphagov/govuk-frontend/releases/download/v4.5.0/release-v4.5.0.zip -o govuk_frontend.zip \
      && unzip -o govuk_frontend.zip -d /usr/src/app/app/static \
      && mv /usr/src/app/app/static/assets/* /usr/src/app/app/static/ \ 
      && rm -rf static/assets govuk_frontend.zip
  
  
  # Copy newly added files to WD
  COPY . .
  
  
  # ---------------------------------------------- Final stage ------------------------------------------------
  FROM python:3.11-alpine3.18 AS final-stage
  
  # Set working directory for final-stage build
  WORKDIR /usr/src/app
  
  # Copy only the necessary built Python dependencies from the single-stage build into the final image to reduce the runtime image size.
  COPY --from=single-stage /usr/local/lib/python3.11/site-packages/ /usr/local/lib/python3.11/site-packages/
  
  # Copy the application code from the single stage build
  COPY --from=single-stage /usr/src/app /usr/src/app
  
  #Path
  ENV PATH="/usr/src/app:${PATH}"
  
  ARG d
  
  # Expose port the container listens on
  EXPOSE 80
  
  # Command to launch app
  CMD ["python3", "-m", "flask", "run", "-h", "0.0.0.0", "-p", "80"]
  