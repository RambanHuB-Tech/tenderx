-- SQL Migration: Update existing TenderX clients with default contact info and password prefixing

UPDATE public.clients
SET 
    -- 1. Set default contact information if NULL or blank
    email = CASE 
        WHEN email IS NULL OR trim(email) = '' THEN 'taxpointramban@gmail.com'
        ELSE email
    END,
    phone = CASE 
        WHEN phone IS NULL OR trim(phone) = '' THEN '7051140752'
        ELSE phone
    END,
    
    -- 2. Update GST password format: prepend 'Aqib' to non-empty passwords (if not already prepended)
    gst_password = CASE 
        WHEN gst_password IS NULL OR trim(gst_password) = '' THEN gst_password
        WHEN gst_password LIKE 'Aqib%' THEN gst_password
        ELSE 'Aqib' || gst_password
    END;
