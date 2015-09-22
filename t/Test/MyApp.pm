
use utf8;
use Mojolicious::Lite;
get '/' => 'index';
any '/test' => sub {
    my $c = shift;

    $c->render( json => $c->req->params->to_hash );
};

app->start;

1;

__DATA__

@@index.html.ep

<!DOCTYPE html>
<html lang="en">
<meta charset="utf-8">
<title>42</title>

<form action="/test" method="POST" id="one">
  <p>Test</p>
  <input type="text" name="a" value="A">
  <input type="checkbox" checked name="b" value="B">
  <input type="checkbox" name="c" value="C">
  <input type="radio" name="d" value="D">
  <input type="radio" checked name="e" value="E">
  <input type="radio" name="e" value="Z">
  <input type="hidden" name="$&quot;bar" value="42">
  <input type="hidden" name="©☺♥" value="24">
  <select name="f" multiple>
    <option value="F">G</option>
    <optgroup label="Options">
      <option>H</option>
      <option selected>I</option>
    </optgroup>
    <option value="J" selected>K</option>
  </select>
  <select name="n"><option>N</option></select>
  <select name="l"><option selected>L</option></select>
  <textarea name="m">M</textarea>
  <button name="o" value="O">No!</button>
  <input type="button" name="s" value="S">
  <input type="submit" name="p" value="P">
  <input type="image" src="/" name="z" alt="z">
</form>
<form action="/test" id="two"><input type="submit" name="q" value="Q"></form>
<form action="/test" id="three"><input type="button" name="r" value="R"></form>
<form action="/test" id="four">
    <input type="image" src="/" name="z" alt="Z">
</form>
<form action="/test" id="five"></form>