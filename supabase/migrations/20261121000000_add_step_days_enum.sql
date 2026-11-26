-- Add step_days to the objective_metric enum in its own migration so subsequent
-- migrations can reference it safely in a separate transaction.
alter type public.objective_metric add value if not exists 'step_days';
