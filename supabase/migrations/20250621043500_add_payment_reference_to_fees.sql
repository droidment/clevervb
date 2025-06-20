-- Migration: Add payment_reference column to st_fees
-- Generated on 2025-06-21

ALTER TABLE public.st_fees
ADD COLUMN IF NOT EXISTS payment_reference TEXT; 