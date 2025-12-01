"""
DermFuse - AI Model Training Script
Custom Deep Learning Model for Skin Lesion Classification

This script demonstrates the training pipeline used to create the DermFuse model.
The model is trained on 50K+ skin lesion images from the ISIC dataset.

Author: DermFuse Team
Date: January 2025
"""

import os
import numpy as np
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers, models
from tensorflow.keras.applications import EfficientNetB3
from tensorflow.keras.optimizers import Adam
from tensorflow.keras.callbacks import (
    EarlyStopping, ModelCheckpoint, ReduceLROnPlateau, TensorBoard
)
from tensorflow.keras.preprocessing.image import ImageDataGenerator
import matplotlib.pyplot as plt
from sklearn.metrics import (
    classification_report, confusion_matrix, roc_auc_score, 
    roc_curve, auc
)
import seaborn as sns

# ============================================================================
# CONFIGURATION
# ============================================================================

class Config:
    """Training configuration"""
    # Dataset
    DATASET_PATH = 'data/ISIC_2024'
    TRAIN_PATH = 'data/processed/train'
    VAL_PATH = 'data/processed/val'
    TEST_PATH = 'data/processed/test'
    
    # Model
    IMAGE_SIZE = (224, 224)
    NUM_CLASSES = 7
    BATCH_SIZE = 32
    
    # Training
    EPOCHS = 50
    LEARNING_RATE = 0.001
    VALIDATION_SPLIT = 0.2
    
    # Callbacks
    EARLY_STOPPING_PATIENCE = 10
    REDUCE_LR_PATIENCE = 5
    
    # Output
    MODEL_SAVE_PATH = 'models/checkpoints/best_model.h5'
    TFLITE_MODEL_PATH = 'models/dermfuse_model.tflite'
    RESULTS_PATH = 'results/'
    
    # Disease classes
    DISEASE_CLASSES = [
        'melanoma',
        'basal_cell_carcinoma',
        'squamous_cell_carcinoma',
        'benign_nevi',
        'dermatofibroma',
        'vascular_lesions',
        'other_conditions'
    ]


# ============================================================================
# DATA LOADING & PREPROCESSING
# ============================================================================

def create_data_generators():
    """Create data generators for training and validation"""
    
    # Training data augmentation
    train_datagen = ImageDataGenerator(
        rescale=1./255,
        rotation_range=20,
        width_shift_range=0.2,
        height_shift_range=0.2,
        horizontal_flip=True,
        vertical_flip=True,
        zoom_range=0.2,
        brightness_range=[0.8, 1.2],
        fill_mode='nearest',
        validation_split=0.2
    )
    
    # Validation data (no augmentation)
    val_datagen = ImageDataGenerator(rescale=1./255)
    
    return train_datagen, val_datagen


def load_training_data(config):
    """Load training and validation data"""
    
    train_datagen, val_datagen = create_data_generators()
    
    # Load training data
    train_generator = train_datagen.flow_from_directory(
        config.TRAIN_PATH,
        target_size=config.IMAGE_SIZE,
        batch_size=config.BATCH_SIZE,
        class_mode='categorical',
        subset='training'
    )
    
    # Load validation data
    val_generator = val_datagen.flow_from_directory(
        config.VAL_PATH,
        target_size=config.IMAGE_SIZE,
        batch_size=config.BATCH_SIZE,
        class_mode='categorical'
    )
    
    return train_generator, val_generator


def load_test_data(config):
    """Load test data"""
    
    test_datagen = ImageDataGenerator(rescale=1./255)
    
    test_generator = test_datagen.flow_from_directory(
        config.TEST_PATH,
        target_size=config.IMAGE_SIZE,
        batch_size=config.BATCH_SIZE,
        class_mode='categorical',
        shuffle=False
    )
    
    return test_generator


# ============================================================================
# MODEL ARCHITECTURE
# ============================================================================

def build_model(config):
    """Build EfficientNetB3-based model for skin lesion classification"""
    
    # Load pre-trained EfficientNetB3
    base_model = EfficientNetB3(
        input_shape=(*config.IMAGE_SIZE, 3),
        weights='imagenet',
        include_top=False
    )
    
    # Freeze base model weights (transfer learning)
    base_model.trainable = False
    
    # Build custom top layers
    model = models.Sequential([
        layers.Input(shape=(*config.IMAGE_SIZE, 3)),
        
        # Base model
        base_model,
        
        # Global pooling
        layers.GlobalAveragePooling2D(),
        
        # Dense layers with dropout
        layers.Dense(512, activation='relu'),
        layers.BatchNormalization(),
        layers.Dropout(0.5),
        
        layers.Dense(256, activation='relu'),
        layers.BatchNormalization(),
        layers.Dropout(0.4),
        
        layers.Dense(128, activation='relu'),
        layers.BatchNormalization(),
        layers.Dropout(0.3),
        
        # Output layer
        layers.Dense(config.NUM_CLASSES, activation='softmax')
    ])
    
    return model, base_model


# ============================================================================
# TRAINING
# ============================================================================

def create_callbacks(config):
    """Create training callbacks"""
    
    callbacks = [
        # Early stopping
        EarlyStopping(
            monitor='val_loss',
            patience=config.EARLY_STOPPING_PATIENCE,
            restore_best_weights=True,
            verbose=1
        ),
        
        # Model checkpoint
        ModelCheckpoint(
            config.MODEL_SAVE_PATH,
            monitor='val_accuracy',
            save_best_only=True,
            verbose=1
        ),
        
        # Reduce learning rate
        ReduceLROnPlateau(
            monitor='val_loss',
            factor=0.5,
            patience=config.REDUCE_LR_PATIENCE,
            min_lr=1e-7,
            verbose=1
        ),
        
        # TensorBoard
        TensorBoard(
            log_dir='logs/',
            histogram_freq=1,
            write_graph=True
        )
    ]
    
    return callbacks


def train_model(model, train_generator, val_generator, config):
    """Train the model"""
    
    # Compile model
    optimizer = Adam(learning_rate=config.LEARNING_RATE)
    model.compile(
        optimizer=optimizer,
        loss='categorical_crossentropy',
        metrics=['accuracy', keras.metrics.AUC(), keras.metrics.Precision()]
    )
    
    print("\n" + "="*70)
    print("PHASE 1: TRANSFER LEARNING (Frozen Base Model)")
    print("="*70)
    
    # Phase 1: Train with frozen base model
    history_phase1 = model.fit(
        train_generator,
        validation_data=val_generator,
        epochs=20,
        callbacks=create_callbacks(config),
        verbose=1
    )
    
    print("\n" + "="*70)
    print("PHASE 2: FINE-TUNING (Unfrozen Base Model)")
    print("="*70)
    
    # Phase 2: Unfreeze and fine-tune
    base_model = model.layers[1]  # Get base model
    base_model.trainable = True
    
    # Freeze early layers, unfreeze last 2 blocks
    for layer in base_model.layers[:-50]:
        layer.trainable = False
    
    # Recompile with lower learning rate
    optimizer = Adam(learning_rate=config.LEARNING_RATE * 0.1)
    model.compile(
        optimizer=optimizer,
        loss='categorical_crossentropy',
        metrics=['accuracy', keras.metrics.AUC()]
    )
    
    # Continue training
    history_phase2 = model.fit(
        train_generator,
        validation_data=val_generator,
        epochs=30,
        initial_epoch=20,
        callbacks=create_callbacks(config),
        verbose=1
    )
    
    return model, history_phase1, history_phase2


# ============================================================================
# EVALUATION
# ============================================================================

def evaluate_model(model, test_generator, config):
    """Evaluate model on test set"""
    
    print("\n" + "="*70)
    print("MODEL EVALUATION")
    print("="*70)
    
    # Get predictions
    predictions = model.predict(test_generator)
    y_pred = np.argmax(predictions, axis=1)
    y_true = test_generator.classes
    
    # Calculate metrics
    accuracy = np.mean(y_pred == y_true)
    print(f"\nTest Accuracy: {accuracy:.4f}")
    
    # Classification report
    print("\nClassification Report:")
    print(classification_report(
        y_true, y_pred,
        target_names=config.DISEASE_CLASSES
    ))
    
    # Confusion matrix
    cm = confusion_matrix(y_true, y_pred)
    print("\nConfusion Matrix:")
    print(cm)
    
    # Plot confusion matrix
    plt.figure(figsize=(10, 8))
    sns.heatmap(cm, annot=True, fmt='d', cmap='Blues',
                xticklabels=config.DISEASE_CLASSES,
                yticklabels=config.DISEASE_CLASSES)
    plt.title('Confusion Matrix')
    plt.ylabel('True Label')
    plt.xlabel('Predicted Label')
    plt.tight_layout()
    plt.savefig(os.path.join(config.RESULTS_PATH, 'confusion_matrix.png'))
    print(f"\nConfusion matrix saved to {config.RESULTS_PATH}")
    
    return accuracy, predictions


def plot_training_history(history_phase1, history_phase2, config):
    """Plot training history"""
    
    fig, axes = plt.subplots(1, 2, figsize=(15, 5))
    
    # Accuracy
    axes[0].plot(history_phase1.history['accuracy'], label='Phase 1 Train')
    axes[0].plot(history_phase1.history['val_accuracy'], label='Phase 1 Val')
    axes[0].plot(
        range(20, 50),
        history_phase2.history['accuracy'],
        label='Phase 2 Train'
    )
    axes[0].plot(
        range(20, 50),
        history_phase2.history['val_accuracy'],
        label='Phase 2 Val'
    )
    axes[0].set_xlabel('Epoch')
    axes[0].set_ylabel('Accuracy')
    axes[0].set_title('Model Accuracy')
    axes[0].legend()
    axes[0].grid(True)
    
    # Loss
    axes[1].plot(history_phase1.history['loss'], label='Phase 1 Train')
    axes[1].plot(history_phase1.history['val_loss'], label='Phase 1 Val')
    axes[1].plot(
        range(20, 50),
        history_phase2.history['loss'],
        label='Phase 2 Train'
    )
    axes[1].plot(
        range(20, 50),
        history_phase2.history['val_loss'],
        label='Phase 2 Val'
    )
    axes[1].set_xlabel('Epoch')
    axes[1].set_ylabel('Loss')
    axes[1].set_title('Model Loss')
    axes[1].legend()
    axes[1].grid(True)
    
    plt.tight_layout()
    plt.savefig(os.path.join(config.RESULTS_PATH, 'training_history.png'))
    print(f"Training history saved to {config.RESULTS_PATH}")


# ============================================================================
# MODEL CONVERSION
# ============================================================================

def convert_to_tflite(model_path, output_path, quantize=True):
    """Convert Keras model to TensorFlow Lite"""
    
    print("\n" + "="*70)
    print("CONVERTING MODEL TO TENSORFLOW LITE")
    print("="*70)
    
    # Load model
    model = keras.models.load_model(model_path)
    
    # Create converter
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    
    if quantize:
        print("Applying quantization...")
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        converter.target_spec.supported_ops = [
            tf.lite.OpsSet.TFLITE_BUILTINS_INT8
        ]
    
    # Convert
    tflite_model = converter.convert()
    
    # Save
    with open(output_path, 'wb') as f:
        f.write(tflite_model)
    
    # Get file size
    file_size_mb = os.path.getsize(output_path) / (1024 * 1024)
    print(f"✅ Model converted successfully!")
    print(f"📦 Output: {output_path}")
    print(f"📊 Size: {file_size_mb:.2f} MB")


# ============================================================================
# MAIN
# ============================================================================

def main():
    """Main training pipeline"""
    
    config = Config()
    
    # Create output directories
    os.makedirs(config.RESULTS_PATH, exist_ok=True)
    os.makedirs(os.path.dirname(config.MODEL_SAVE_PATH), exist_ok=True)
    
    print("\n" + "="*70)
    print("DERMFUSE - AI MODEL TRAINING")
    print("="*70)
    print(f"Image Size: {config.IMAGE_SIZE}")
    print(f"Batch Size: {config.BATCH_SIZE}")
    print(f"Epochs: {config.EPOCHS}")
    print(f"Learning Rate: {config.LEARNING_RATE}")
    print(f"Number of Classes: {config.NUM_CLASSES}")
    print("="*70 + "\n")
    
    # Load data
    print("Loading training data...")
    train_generator, val_generator = load_training_data(config)
    print("✅ Training data loaded")
    
    print("Loading test data...")
    test_generator = load_test_data(config)
    print("✅ Test data loaded\n")
    
    # Build model
    print("Building model...")
    model, base_model = build_model(config)
    print("✅ Model built")
    print(f"Model Parameters: {model.count_params():,}\n")
    
    # Train model
    print("Starting training...")
    model, history_phase1, history_phase2 = train_model(
        model, train_generator, val_generator, config
    )
    print("✅ Training completed\n")
    
    # Evaluate model
    accuracy, predictions = evaluate_model(model, test_generator, config)
    
    # Plot history
    plot_training_history(history_phase1, history_phase2, config)
    
    # Convert to TFLite
    convert_to_tflite(
        config.MODEL_SAVE_PATH,
        config.TFLITE_MODEL_PATH,
        quantize=True
    )
    
    print("\n" + "="*70)
    print("✅ TRAINING PIPELINE COMPLETED SUCCESSFULLY")
    print("="*70)
    print(f"Model saved: {config.MODEL_SAVE_PATH}")
    print(f"TFLite model: {config.TFLITE_MODEL_PATH}")
    print(f"Results: {config.RESULTS_PATH}")
    print("="*70 + "\n")


if __name__ == '__main__':
    main()
