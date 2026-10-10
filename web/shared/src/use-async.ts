import { type DependencyList, useCallback, useEffect, useState } from 'react';

export interface AsyncState<T> {
  data: T | undefined;
  error: Error | undefined;
  loading: boolean;
  reload: () => void;
}

/** Minimal data hook: runs `load` when deps change, ignores stale responses, exposes reload. */
export function useAsync<T>(load: () => Promise<T>, deps: DependencyList): AsyncState<T> {
  const [state, setState] = useState<{ data?: T; error?: Error; loading: boolean }>({ loading: true });
  const [nonce, setNonce] = useState(0);

  useEffect(() => {
    let live = true;
    setState((s) => ({ data: s.data, loading: true }));
    load().then(
      (data) => live && setState({ data, loading: false }),
      (error: unknown) => live && setState({ error: error instanceof Error ? error : new Error(String(error)), loading: false }),
    );
    return () => {
      live = false;
    };
    // The caller owns `deps`; `load` is intentionally not one of them.
  }, [...deps, nonce]);

  const reload = useCallback(() => setNonce((n) => n + 1), []);
  return { data: state.data, error: state.error, loading: state.loading, reload };
}
