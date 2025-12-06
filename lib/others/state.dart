class State<S, A> {
  // The core function: takes a state (S), returns a value (A) and a new state (S)
  final (A, S) Function(S state) run;

  State(this.run);

  // --- THE DO CONSTRUCTOR ---
  static State<S, A> doNotation<S, A>(
    A Function(T Function<T>(State<S, T>) $) callback,
  ) {
    // We return a NEW State function
    return State<S, A>((initialState) {
      // 1. Capture the state in a mutable variable
      var currentState = initialState;

      // 2. Define the resolver function ($)
      // This function updates the mutable 'currentState' every time it is called
      T resolver<T>(State<S, T> stateOp) {
        final result = stateOp.run(currentState);
        currentState = result.$2; // Update state!
        return result.$1; // Return value
      }

      // 3. Run the user's imperative code block using our resolver
      final resultValue = callback(resolver);

      // 4. Return the final value and the final state
      return (resultValue, currentState);
    });
  }

  // --- Helpers for the example ---

  // Get the current state
  static State<S, S> get<S>() {
    return State((s) => (s, s));
  }

  // Replace the current state
  static State<S, void> put<S>(S newState) {
    return State((_) => ((), newState)); // returns void as value
  }
}
