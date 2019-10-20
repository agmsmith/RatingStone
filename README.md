# The Rating Stone Project

This is a reputation system layered on top of the sample application for
[*Ruby on Rails Tutorial: Learn Web Development with Rails*]
(https://www.railstutorial.org/) (6th Edition) by
[Michael Hartl](https://www.michaelhartl.com/).

## License

The public version of the reputation system is licensed under the GNU General
Public License version 3.  The general idea is that if you use the code, you
should contribute your changes back to the public.  See [LICENSE.md](LICENSE.md)
for details.

All source code in the [Ruby on Rails Tutorial](https://www.railstutorial.org/)
is available jointly under the MIT License and the Beerware License.

## Getting started

To get started with the app, clone the repo and then install the needed gems
(assuming Ruby 2.6 and Rails 6.0 are already installed):

```
$ bundle install --without production
```

Next, migrate the database:

```
$ rails db:migrate
```

Finally, run the test suite to verify that everything is working correctly:

```
$ rails test
```

If the test suite passes, you'll be ready to run the app in a local server:

```
$ rails server
```

For more information, see the
[*Ruby on Rails Tutorial* book](https://www.railstutorial.org/book).
