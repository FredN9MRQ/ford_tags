# Simple calculator functions
from typing import Union

def add(a: int, b: int) -> int:
    """Add two integers."""
    return a + b

def subtract(a: int, b: int) -> int:
    """Subtract two integers."""
    return a - b

def multiply(a: int, b: int) -> int:
    """Multiply two integers."""
    return a * b

def divide(a: Union[int, float], b: Union[int, float]) -> Union[int, float]:
    """Divide two numbers. Raises ValueError if divisor is zero."""
    if b == 0:
        raise ValueError("Cannot divide by zero.")
    return a / b
